# Keras API Doc

# 1. Layers

## 1.1 Overview


## 1.2 Lambda

如果你只是想对流经该层的数据做个变换，而这个变换本身没有什么需要学习的参数，那么直接用Lambda Layer是最合适的了。

注意，用Lambda自定义函数时，记X为输入Tensor，可以对X整体赋值，但不能对X中的元素(比如`X[:, :, :0]`)赋值。以下代码会报错：`'Tensor' object does not support item assignment`

```python
def func1(x):
    x[:,:,:,0] = (x[:,:,:,0] - m[0]) / (2 * s[0]) + 0.5
    x[:,:,:,1] = (x[:,:,:,1] - m[1]) / (2 * s[1]) + 0.5
    x[:,:,:,2] = (x[:,:,:,2] - m[2]) / (2 * s[2]) + 0.5
    return x
```
解决方案：先使用中间变量赋值，再使用tf.stack合在一起，注意X是4维而非3维
```python
def func2(x):
    x0 = (x[:,:,:,0] - m[0]) / (2 * s[0]) + 0.5
    x1 = (x[:,:,:,1] - m[1]) / (2 * s[1]) + 0.5
    x2 = (x[:,:,:,2] - m[2]) / (2 * s[2]) + 0.5
    return tf.stack([x0, x1, x2], 3)
```

## 1.3 Masking

`keras.layers.Masking(mask_value=0.0)`

对输入的序列信号中等于给定值mask_value的timestep(其实是元素级)进行屏蔽，实际操作是保留这一timestep，只是不参与计算。

应用场景1：输入数据X中，缺少时间步长3和5对应的信号，希望将其掩盖，然后才能输入LSTM层
```python
X[:, 3, :] = 0.
X[:, 5, :] = 0.
```

应用场景2：处理变长文本时，需要先统一长度进行Padding，随后在输入LSTM前，需要反Padding，也就是把Pad的0（以及序列本来就有的0）去掉
```python
X = sequence.pad_sequence(maxlen=10, value=0, padding='post')
```

两种应用场景下，都需要进行Masking
```python
model = Sequential()
model.add(Masking(mask_value=0., input_shape=(timesteps, embed_dim)))
model.add(LSTM(32))
```

不支持Masking的层：CNN, Flatten, Reshape, Concatenate等

如果后续层不支持masking，则抛出异常，此时需要自定义该层([Reference](https://stackoverflow.com/questions/39510809/mean-or-max-pooling-with-masking-support-in-keras))或别的方法(参考Libray, Code和Article)

#### Library

- <https://github.com/CyberZHG/keras-trans-mask>

    Remove and restore masks for layers that do not support masking.

#### Code

- [Keras实现支持masking的Flatten层](https://blog.csdn.net/songbinxu/article/details/80254122)

- [Keras自定义实现带masking的meanpooling层](https://blog.csdn.net/songbinxu/article/details/80148856)

#### Article

- [使用Keras和Pytorch处理RNN变长序列输入的方法总结](https://zhuanlan.zhihu.com/p/63219625)

- [对keras函数中mask的个人理解](https://blog.csdn.net/lby503274708/article/details/94596068)

- [Keras中关于Recurrent Network的Padding与Masking](http://ju.outofmemory.cn/entry/352106)
  
- [Keras中Embedding层masking与Concatenate层不可调和的矛盾](https://blog.csdn.net/songbinxu/article/details/80242211)

- [Support for masking in flatten and reshape layers](https://github.com/keras-team/keras/issues/4978)

- [keras中的mask操作](https://www.cnblogs.com/databingo/p/9339175.html)

#### Question

Masking与Embedding(mask_zero=True)啥关系？同时使用？只使用前者？只使用后者？ Masking+Embedding(mask_zero=False)同时使用呢？？？

RNN API中的Masking处写道：This layer supports masking for input data with a variable number of timesteps. To introduce masks to your data, use an Embedding layer with the mask_zero parameter set to True. ？？？<https://keras.io/layers/recurrent/>


## 1.4 TimeDistributed

**解读1**：TimeDistributed层给予模型一对多，多对多的能力，增加了模型的维度，多用于RNN/LSTM/GRU后面

![](https://raw.githubusercontent.com/liuyaox/ImageHosting/master/for_markdown/keras_timedistributed_image.png)

TimeDistributed层在每个时间步上均操作一个Layer(Dense/CNN/RNN?等)，类似于最右侧many-to-many，如果使用正常的Layer，最后只会得到一个结果。

TimeDistributedDense: 

The most common scenario for using TimeDistributedDense is using a RNN for tagging task.e.g. POS labeling or slot filling task. In this kind of task:

For each sample, the input is a sequence (a1,a2,a3,a4...aN) and the output is a sequence (b1,b2,b3,b4...bN) with the same length. bi could be viewed as the label of ai.

Push a1 into a RNN to get output b1. Than push a2 and the hidden output of a1 to get b2...  If you want to model this by Keras, you just need to used a TimeDistributedDense after a RNN or LSTM layer(with return_sequence=True) to make the cost function is calculated on all time-step output. If you don't use TimeDistributedDense ans set RNN's return_sequence=False, then the cost is calculated on the last time-step output and you could only get the last bN.

Reference: <https://github.com/keras-team/keras/issues/1029>

**解读2**：TimeDistributed(Layer)表示**在每个Timestep后都加一个Layer**，各Layer参数权重共享，Layer可为Dense/CNN/RNN?等

```python
# 应用于Dense，12个timestep后都各加一个Dense，不过各Dense参数共享，参数量为8*10+10=90
inputs = Input(shape=(12, 8))              # 输入维度(None, 12, 8)
out = TimeDistributed(Dense(10))(inputs)   # 输出维度(None, 12, 10)

# 应用于Conv2D，12个timestep后都各加一个Conv2D，不过各Conv2D参数共享，参数量为3*3*3*32+32=896
inputs = Input(shape=(12, 32, 32, 3))
out = TimeDistributed(Conv2D(filters=32, kernel_size=(3, 3), padding='same'))(inputs)

# 作为对比，不使用TimeDistributed
inputs = Input(shape=(32, 32, 3))             # 一般情况下没有timestep数量
out = Conv2D(filters=32, kernel_size=(3, 3), padding='same')(inputs)
```
Reference: [TimeDistributed的理解和用法 - 2018](https://blog.csdn.net/zh_JNU/article/details/85160379)

```python
inputs = Input(shape=(10, 32))                # (None, 10, 32)
X = LSTM(16, return_sequences=True)(inputs)   # (None, 10, 16)
out = TimeDistributed(Dense(4))(X)            # (None, 10, 4)

# 作为对比，不使用TimeDistributed
X = LSTM(16, return_sequences=False)(inputs)  # (None, 16)
out = Dense(4)(X)                             # (None, 4)
```
Reference: [How to Use the TimeDistributed Layer in Keras - 2017](https://machinelearningmastery.com/timedistributed-layer-for-long-short-term-memory-networks-in-python/)


## 1.8 Custom Layer

Doc: <https://keras.io/layers/writing-your-own-keras-layers/>

#### Practice

- [使用Keras编写自定义网络层 - 2018](https://blog.csdn.net/u013084616/article/details/79295857)


# 2. Models

# 2.1 Overview


# 2.2 K.function VS Model

[获取中间层的输出](https://keras.io/getting-started/faq/#how-can-i-obtain-the-output-of-an-intermediate-layer)



# 9. Others

## 9.1 Other Content

官方文档中没有的内容

#### preprocessing.image/text/sequence

```python
from keras.preprocessing import image, text, sequence

# 文档中已有
image.ImageDataGenerator
text.text_to_word_sequence
text.Tokenizer
text.hashing_trick
text.one_hot
sequence.TimeseriesGenerator
sequence.pad_sequences
sequence.skipgrams
sequence.make_sampling_table

# 文档中没有
image.load_img(path, grayscale=False, target_size=None, interpolation='nearest')  # Loads an image into PIL format
image.img_to_array(img, data_format=None)                                         # Converts a PIL Image instance to a Numpy array
image.array_to_img(x, data_format=None, scale=True)                               # Converts a 3D Numpy array to a PIL Image instance
image.list_pictures(directory, ext='jpg|jpeg|bmp|png|ppm')                        # 按照指定的扩展名ext，列出目录下所有pictures
image.random_channel_shift(x, intensity, channel_axis=0)                                                # Random channel shift of a Numpy image tensor
image.random_rotation(x, rg, row_axis=1, col_axis=2, channel_axis=0, fill_mode='nearest', cval=0.0)     # Random rotation of a Numpy image tensor
image.random_shear(x, intensity, row_axis=1, col_axis=2, channel_axis=0, fill_mode='nearest', cval=0.0) # Random spatial shear of a Numpy image tensor
image.random_shift(x, wrg, hrg, row_axis=1, col_axis=2, channel_axis=0, fill_mode='nearest', cval=0.0)  # Random spatial shift of a Numpy image tensor
image.random_zoom(x, zoom_range, row_axis=1, col_axis=2, channel_axis=0, fill_mode='nearest', cval=0.0) # Random spatial zoom of a Numpy image tensor
image.transform_matrix_offset_center(matrix, x, y)

text.maketrans(x, y=None, z=None, /)        # 同str.maketrans
text.OrderedDict(self, /, *args, **kwargs)  # Dictionary that remembers insertion order

image.K                  # module 'keras.backend'
image.linalg             # module 'scipy.linalg' from scipy
image.ndi                # module 'scipy.ndimage' from scipy
image.np                 # module 'numpy'
image.multiprocessing    # module 'multiprocessing'
image.os                 # module 'os'
image.pil_image          # module 'PIL.Image' from PIL
image.re                 # module 're'
image.threading          # module 'threading'
image.warnings           # module 'warnings'
text.string              # module 'string'
text.sys                 # module 'sys'
sequence.random          # module 'random'
```
