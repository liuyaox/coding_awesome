# Keras Debug

a. **ResourceExhaustedError**: OOM when allocating tensor with shape[32,1536,13,13] and type float on /job:localhost/replica:0/task:0/device:GPU:0 by allocator GPU_0_bfc

	 [[Node: training/Adam/gradients/replica_0/model_1/global_average_pooling2d_1/Mean_grad/truediv-0-TransposeNHWCToNCHW-LayoutOptimizer = Transpose[T=DT_FLOAT, Tperm=DT_INT32, _device="/job:localhost/replica:0/task:0/device:GPU:0"](training/Adam/gradients/replica_0/model_1/global_average_pooling2d_1/Mean_grad/Tile, PermConstNHWCToNCHW-LayoutOptimizer)]]

    Hint: If you want to see a list of allocated tensors when OOM happens, add report_tensor_allocations_upon_oom to RunOptions for current allocation info.

[32,1536,13,13] : [32 - Batch Size, 1536 - 某层卷积核的个数, 13 - 图像高, 13 - 图像长]

一种测试办法：把模型从最简单(比如只有一层全连接层)，逐层添加并检查模型，直到遇到OOM问题。

**Method1**：提高分配的显存比例

在创建Session时，通过传递tf.GPUOptions作为可选配置参数的一部分来显式地指定需要分配的显存比例，设置参数per_process_gpu_memory_fraction(默认值为0？？)，该参数指定了每个GPU进程中使用显存的上限，但它只能均匀作用于所有GPU，无法对不同GPU设置不同的上限

```python
# 假如有12GB的显存并使用其中的4GB:
gpu_options = tf.GPUOptions(per_process_gpu_memory_fraction=0.333)
sess = tf.Session(config=tf.ConfigProto(gpu_options=gpu_options))
```

**Method2**：设置动态分配显存

分配器不指定所有的GPU内存，而是在程序运行时，根据程序所需GPU显存情况，分配最小的资源 

```python
config = tf.ConfigProto()
config.gpu_options.allow_growth=True
sess = tf.Session(config=config)
```


b. **TypeError**: 'Tensor' object does not support item assignment

    ---> 23     x[:,:,0] -= m[0]

**Explanation**：对tensor中某些元素赋值存在问题，对tensor整体赋值可行。

**Method**：使用中间变量赋值，然后stack在一起，注意X的维度，有时是4维(加上batch_size)

**Reference**：https://blog.csdn.net/ghy_111/article/details/80839666

