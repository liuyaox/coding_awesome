# Tensorflow Overview

# 1. Overview


# 2. Concept

**Graph**:

使用Graph来描述一系列操作，可使运行效率提高，其原因：为了用python实现高效的数值计算，我们通常会使用函数库，比如NumPy，会把类似矩阵乘法这样的复杂运算使用其他外部语言实现。但从外部计算切换回Python的每一个操作，仍然是一个很大的开销。如果用GPU来进行外部计算，开销会更大。用分布式的计算方式，也会花费更多的资源用来传输数据。

TensorFlow也把复杂的计算放在Python之外完成，但为了避免前面说的那些开销，它做了进一步完善。Tensorflow**不单独运行单一**的复杂计算，而是先**用Graph描述一系列可交互的计算操作**，然后**全部一起**在Python之外运行，避免了外部与Python之间**多次来回切换**的开销。

这与Theano或Torch的做法类似。因此Python代码的目的是用来构建这个可以在外部运行的计算图，以及安排计算图的哪一部分应该被运行。即：Python(构建计算图，安排计算图运行部分) + 其他语言(进行复杂运算)


**Session**:

Tensorflow依赖于一个**高效的C++后端**来进行计算，与C++后端的连接叫做Session。一般而言，使用TensorFlow程序的流程是先创建一个图，然后在Session中启动它。有2种Session：

- Session类：需要在启动Session之前构建好整个计算图Graph，然后启动该计算图Graph。

- InteractiveSession类：通过它，可以更加灵活地构建代码。它能在运行Graph时插入一些计算图（由某些操作Operations构成）。这对于工作在交互式环境中的人们来说非常便利，如使用IPython。



# 3. Softmax模型

## 3.1 Model Build

```python
# 定义输入变量：placeholder是个占位符，一个待定符号变量，在定义时可以定义其格式和维度，可以用来表示输入值
x = tf.placeholder('float', [None,784])  # 表示一个float格式的任何行*784列的张量x

# 定义模型参数：Variable代表一个可修改的张量，存在于描述交互性操作的Graph中，用于计算输入值，或在计算中被修改，机器学习模型的参数可用Variable表示
W = tf.Variable(tf.zeros([784,10]))  # 表示一个784行*10列的初始值为0的参数
b = tf.Variable(tf.zeros([10]))

# 定义模型：设置完变量和参数后，定义模型很简单
y = tf.nn.softmax(tf.matmul(x,W) + b)
```

## 3.2 Model Train & Evaluate

### 3.2.1 Cost Function

成本函数：交叉熵，用来衡量我们的预测描述真相的低效性。
```python
y_ = tf.placeholder('float', [None,10])         # 添加一个新占位符
cross_entropy = -tf.reduce_sum(y_*tf.log(y))    # 定义交叉熵
```

### 3.2.2 Optimizer

TensorFlow拥有一张描述各个计算单元的Graph，它可以自动使用反向传播来有效确定变量是如何影响需要最小化的那个Cost值的。然后，TensorFlow会用选择的优化算法不断地修改变量以降低Cost。
```python
train_step = tf.train.GradientDescentOptimizer(0.01).minimize(cross_entropy)    # 用梯度下降算法以0.01的学习速率最小化交叉熵
```

实际上，TensorFlow在这里所做的是，它在后台的当前Graph里，增加一系列新的计算操作（如计算梯度，计算每个参数的步长变化，计算新的参数值）用于实现反向传播算法和梯度下降算法，然后返回一个单一的操作train_step。当运行这个操作时，它用梯度下降算法训练模型，微调变量，不断减少成本。

### 3.2.3 Model Train

```python
# 创建Session并初始化变量(W,b)
init = tf.global_variables_initializer()
sess = tf.Session()
sess.run(init)

# 开始训练：循环训练1000次，每一次里，随机抓取训练数据中的100个批处理数据点，然后用这些数据点替换之前的占位符来运行train_step
for i in range(1000):
    batch_xs, batch_ys = mnist.train.next_batch(100)
    sess.run(train_step, feed_dict={x: batch_xs, y_: batch_ys})
```

## 3.2.4 Model Evaluate

```python
correct_prediction = tf.equal(tf.argmax(y,1), tf.argmax(y_,1))              # 计算预测值与真实值的匹配情况
accuracy = tf.reduce_mean(tf.cast(correct_prediction, "float"))             # 根据匹配情况定义正确率
sess.run(accuracy, feed_dict={x: mnist.test.images, y_: mnist.test.labels}) # 执行正确率的计算
```


# 4. 深度卷积神经网络模型

# 4.1 Initialization

使用CNN，需要创建大量的权重和偏置项。权重在初始化时应该加入少量的噪声来打破对称性以及避免0梯度。由于使用的是ReLU神经元，因此比较好的做法是用一个较小的正数来初始化偏置项，以避免神经元节点输出恒为0。为了不在建立模型的时候反复初始化操作，定义两个函数用于初始化。
```python
def weight_variable(shape):
    initial = tf.truncated_normal(shape, stddev=0.1)
    return tf.Variable(initial)

def bias_variable(shape):
    initial = tf.constant(0.1, shape=shape)
    return tf.Variable(initial)
```

# 4.2 Model Build

## 4.2.1 CNN & Pooling

使用vanilla版本：步长stride size=1，使用padding，池化为2*2的max pooling。抽象为一个函数：
```python
#卷积和池化
def conv2d(x, W):
    return tf.nn.conv2d(x, W, strides=[1,1,1,1], padding='SAME', use_cudnn_on_gpu=False)	#strides=[1, stride_width, stride_height, 1]
def max_pool_2x2(x):
    return tf.nn.max_pool(x, ksize=[1,2,2,1], strides=[1,2,2,1], padding='SAME')	#ksize是window的size，
```

## 4.2.2 First CNN Layer

它由一个卷积接一个max pooling完成。卷积的权重张量形状是[5, 5, 1, 32]，前两个维度是patch的大小，接着是输入的channel数目，最后是输出的channel数目（即filter的个数）。而对于每一
个输出channel都有一个对应的偏置量。
```python
W_conv1 = weight_variable([5, 5, 1, 32])	#32个5*5*1的filter/patch，filter的shape为[height, width, channel_num, filter_num]
b_conv1 = bias_variable([32])		#每个filter对应1个偏置，共32个
```

为了用这一层，把x变成一个4d向量x_image，把x_image和权值向量进行卷积，加上偏置项，应用ReLU激活函数，最后进行max pooling。
```python
x_image = tf.reshape(x, [-1,28,28,1])       #x_num(若x的第1维取值为x_num)个28*28*1的图片，x_image的shape为[x_num, width, height, channel_num]
h_conv1 = tf.nn.relu(conv2d(x_image, W_conv1) + b_conv1)	#维度是28*28*32
h_pool1 = max_pool_2x2(h_conv1)				                #维度是14*14*32
```

## 4.2.3 Second CNN Layer

```python
W_conv2 = weight_variable([5, 5, 32, 64])	#64个5*5*32的filter
b_conv2 = bias_variable([64])
h_conv2 = tf.nn.relu(conv2d(h_pool1, W_conv2) + b_conv2)	#维度是14*14*64
h_pool2 = max_pool_2x2(h_conv2)				#维度是7*7*64
```

## 4.2.4 Fully-Connected Layer

```python
# 现在图片尺寸减小到7*7，然后加入一个有1024个神经元的全连接层
W_fc1 = weight_variable([7 * 7 * 64, 1024])
b_fc1 = bias_variable([1024])

# 把池化层输出的张量reshape成一些向量，乘上权重矩阵，加上偏置，然后对其使用ReLU
h_pool2_flat = tf.reshape(h_pool2, [-1, 7*7*64])		#把h_pool2完全平铺成1维，即1*(7*7*64)
h_fc1 = tf.nn.relu(tf.matmul(h_pool2_flat, W_fc1) + b_fc1)	#维度是1*1024
```

## 4.2.5 Dropout

为了减少过拟合，在输出层之前加入dropout。用一个placeholder代表一个神经元的输出在dropout中保持不变的概率。这样可以在训练中启用dropout，在测试中关闭dropout。 TensorFlow的tf.nn.dropout除了可以屏蔽神经元的输出外，还会自动处理神经元输出值的scale，所以用dropout时可以不用考虑scale。
```python
keep_prob = tf.placeholder("float")
h_fc1_drop = tf.nn.dropout(h_fc1, keep_prob)
```

## 4.2.6 Softmax

最后添加一个softmax层，就像前面的单层softmax regression一样。
```python
W_fc2 = weight_variable([1024, 10])				#维度是1024*10
b_fc2 = bias_variable([10])
y_conv=tf.nn.softmax(tf.matmul(h_fc1_drop, W_fc2) + b_fc2)	#维度是1*10
```

## 4.3 Model Train & Evaluate

```python
# 定义成本函数
cross_entropy = -tf.reduce_sum(y_*tf.log(y_conv))
# 定义成本函数优化方法
train_step = tf.train.AdamOptimizer(1e-4).minimize(cross_entropy) #用更复杂的ADAM优化器来做梯度最速下降
# 定义模型评估指标：正确率
correct_prediction = tf.equal(tf.argmax(y_conv,1), tf.argmax(y_,1))
accuracy = tf.reduce_mean(tf.cast(correct_prediction, "float"))

# 开始模型训练和评估
sess.run(tf.global_variables_initializer())
for i in range(20000):
    batch = mnist.train.next_batch(50)
    if i%100 == 0:
        train_accuracy = accuracy.eval(feed_dict={x:batch[0], y_: batch[1], keep_prob: 1.0}) #加入keep_prob来控制dropout比例
        print("step %d, training accuracy %g"%(i, train_accuracy))
    train_step.run(feed_dict={x: batch[0], y_: batch[1], keep_prob: 0.5})
print("test accuracy %g"%accuracy.eval(feed_dict={x:mnist.test.images, y_:mnist.test.labels, keep_prob:1.0}))
```
