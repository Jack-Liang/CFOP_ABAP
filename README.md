# CFOP_ABAP
本程序基于ABAP实现，使用[CFOP法](https://www.speedsolving.com/wiki/index.php/CFOP_method)的思路还原3阶魔方。

## 1. 魔方录入

 <img src="https://github.com/Jack-Liang/CFOP_ABAP/blob/main/pic/%E5%B1%95%E5%BC%80%E5%9B%BE.png" width = "622" height = "460.5" alt="魔方展开图" align=center />

录入时按照黄、橙、蓝、红、绿、白色依次录入，用英文首字母计作：

> YYYYYYYYY
> OOOOOOOOO
> BBBBBBBBB
> RRRRRRRRR
> GGGGGGGGG
> WWWWWWWWW


## 2. 魔方的旋转操作。

按照上述方式录入颜色后，通过算法在三维坐标中模拟魔方，并将对应的颜色记录到对应空间上，在执行R、F等类似算法时，实际上是将对应的立方体沿某个轴进行旋转，则可以使用三维空间的旋转公式计算得到旋转后的位置。

 <img src="https://github.com/Jack-Liang/CFOP_ABAP/blob/main/pic/三维坐标系.jpeg" alt="魔方展开图" align=center />

在旋转过程中，所在轴对应的颜色不变，另外两个轴对应的颜色置换（±90°）。

例如，角块A(1,1,-1)(R,Y,G)执行R操作，此时沿着x轴顺时针旋转90°，对应的A‘的坐标，根据公式：

> x' = x
> 
> y' = y·cos 90° + z·sin 90°
> 
> z' = z·cos 90° - y·sin 90°

所以，A'(1,-1,-1)(R,G,Y)

> 备注：
> 
> cos 90°  = 0
> 
> cos -90° = 0
> 
> sin 90°  = 1
> 
> sin -90° = -1


## 3. A*寻路算法实现Croos算法路径

（待完善）

## 4. 转法的code表示方法

code编码便于在执行旋转过程中的处理

## 5. FOP算法映射

计划使用固定的算法，在匹配到算法表后直接执行

## 6. 打乱公式

为便于测试，会提供随机生成的打乱公式

## 其他

因个人习惯，在使用CFOP过程中，首先白色中心块朝上还原一个白色Cross，之后旋转180°，寻找后续算法，本程序依次运行，在每一阶段会做文字提示。

---

# 参考文献

1. https://github.com/crumpstrr33/CFOP-cube-solver
2. https://www.speedsolving.com/wiki/index.php/CFOP_method
3. https://juejin.cn/post/6970700421035884558

谨对以上文献的作者表示感谢，未竟之处，敬请谅解，欢迎交流指正。

