# Keras Tricks and Tips

# Initialization

#### Article

- [Why default CNN are broken in Keras and how to fix them](https://towardsdatascience.com/why-default-cnn-are-broken-in-keras-and-how-to-fix-them-ce295e5e5f2)

    **YAO**: 默认的初始随机化方法有bug，推荐使用 keiming 方法


# Learning Rate

## LearningRateScheduler

动态学习率，值得好好了解一下



# Overfitting

防止过拟合3种方法：

Dropout: 可放在很多层的后面，常见的是直接放在Dense后面，对于Convolutional和MaxPooling，可放在它俩之间或MaxPooling之后，孰优孰劣需要尝试；大部分放在之间？

Layer的正则化系数: 在定义Layer时加入L1或L2正则化系数xxx_regularizer，如Conv1D的定义：`Conv1D(..., kernel_regularizer=None, bias_regularizer=None, activity_regularizer=None, ...)`

BatchNormalization: 简直神器！可代替Dropout？


# Others

关于Train/Val/Test: Train/Test可以固定划分并保存为文件，Train划分为Train/Val时，可直接在fit时指定validation_split，注意此时fit里的shuffle还未执行，所以建议在划分之前，数据最好先shuffle。