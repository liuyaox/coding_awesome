# Keras Others

## 5.1 Overview

## 5.2 keras_contrib

### 5.2.1 Overview

### 5.2.2 CRF

#### CRF构造函数

**sparse_target**

参数sparse_target=True用于y_true是indices时，表示在计算loss时需要把y_true变成sparse

计算loss时，令y_true由indices变成one-hot: `y_true = K.one_hot(K.cast(y_true[:, :, 0], 'int32'), crf.units)`

计算accuracy时，直接取第3维就是indices: `y_true = K.cast(y_true[:, :, 0], K.dtype(y_pred))`

当y_true是one-hot时，loss和accuracy有另外一套处理方法。

**crf_accuracy**

使用y_true和y_pred计算accuracy时，不能直接使用y_pred，因为此时的y_pred是**训练模式时的输出**，而是从y_pred的_keras_history属性中提取到输出y_pred的那个layer，即crf_layer

再从crf_layer中获得input_tensor和input_mask，然后使用它俩进行viterbi_decoding，以重新计算出y_pred，**应用模式时的输出**y_pred，才可以用于参与计算accuracy。

详情参考以下源代码：

```python
def crf_viterbi_accuracy(y_true, y_pred):
    '''Use Viterbi algorithm to get best path, and compute its accuracy. `y_pred` must be an output from CRF.'''
    crf, idx = y_pred._keras_history[:2]            # _keras_history共有3项：inbound_layer, node_index, tensor_index
    X = crf._inbound_nodes[idx].input_tensors[0]    # crf._inbound_nodes[idx]表示输出y_pred的那个layer，input_tensors为X
    mask = crf._inbound_nodes[idx].input_masks[0]   # input_masks为处理X时的mask   从这里可看出，处理X与处理Y使用的是同一个mask！
    y_pred = crf.viterbi_decoding(X, mask)          # 之前的y_pred是训练模式时的输出，计算accuracy需要的是应用模式时的输出，即Viterbi Decoding
    return _get_accuracy(y_true, y_pred, mask, crf.sparse_target)
```

另外从源代码中可以看出的，也是需要额外注意的是：**处理X与处理Y使用的是同一个mask**，数据预处理时注意一下，保证mask_value是一样的。