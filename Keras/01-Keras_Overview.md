# Keras Overview

#### Article

- [Keras一些基本概念 - 2016](https://blog.csdn.net/u011437229/article/details/53464213)

    **符号计算**:

    Keras底层库使用Theano或TensorFlow，这两个库称为Keras的后端，都是一个符号主义的库。 关于符号计算，可以概括为：

    首先定义各种变量，然后建立一个“计算图”，计算图规定各个变量之间的计算关系。建立好的计算图需要编译，以确定其内部细节，然而此时的计算图还是一个“空壳子”，里面没有任何实际数据，只有把需要运算的数据输入进去后，才能在整个模型中形成数据流，从而形成输出值。 

    Keras的模型搭建形式就是这种方法，在搭建完成Keras模型后，模型是一个空壳子，只有实际生成可调用的函数后(K.function)，输入数据，才会形成真正的数据流。 

    使用计算图的语言如Theano，以难以调试而闻名，没有经验的开发者很难直观感受计算图到底在干什么。尽管很让人头痛，但大多数深度学习框架使用的都是符号计算这一套方法，因为符号计算能够提供关键功能：计算优化、自动求导等。

- [Keras vs. tf.keras: What’s the difference in TensorFlow 2.0? - 2019](https://www.pyimagesearch.com/2019/10/21/keras-vs-tf-keras-whats-the-difference-in-tensorflow-2-0/)

    **Chinese**: [TensorFlow 2.0中的tf.keras和Keras有何区别？为什么以后一定要用tf.keras？](https://mp.weixin.qq.com/s?__biz=MzA3MzI4MjgzMw==&mid=2650775817&idx=4&sn=58476287a3a3550248ce0845a07590cd)
