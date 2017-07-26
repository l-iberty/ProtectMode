# 进入保护模式后打印字符'P'

##　为了直观感受特权级，可以为描述符和描述符对应的选择子设置不同的特权级，观察执行结果，比如：

![LABEL_DESC_VIDEO](screenshot/LABEL_DESC_VIDEO.png)

![Selector_Video](screenshot/Selector_Video.png)

## 另外，32位代码段描述符必须具有`DPL_0`特权级，与对应的选择子无关

