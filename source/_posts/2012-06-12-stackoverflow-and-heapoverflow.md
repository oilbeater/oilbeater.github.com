---
layout: post
title: "栈溢出和堆溢出"
description: "之所以想写这个东西是因为在我年幼无知的时候以为堆和栈是一个东西，然后迷迷糊糊的过了这么多年，直到那阵子面试前翻面经才把世界观给颠覆过来，之后又看了一些相关的东西，才发现这里面有这么多的奥秘。"
tagline: "Hack the life"
category: "安全" 
img: http://lh4.googleusercontent.com/-um7AnWJx3Is/T9cH3NM4QXI/AAAAAAAAASc/mR1biDySqMo/s480/Stack_4.jpg
tags: [技术, 安全]
---
<img src="http://lh4.googleusercontent.com/-um7AnWJx3Is/T9cH3NM4QXI/AAAAAAAAASc/mR1biDySqMo/s480/Stack_4.jpg" alt="" style="width:150px;height:170px;">
<p>
    之所以想写这个东西是因为在我年幼无知的时候以为堆和栈是一个东西，然后迷迷糊糊的过了这么多年，直到那阵子面试前翻面经才把世界观给颠覆过来，之后又看了一些相关的东西，才发现这里面有这么多的奥秘，在这期间还发现本善良人手册写得很不错。
</p>
<h2>堆和栈是怎样两个东西？</h2>
<p>栈在英语里是stack，堆在英语里是heap，两个完全不一样的东西。</p>
<h3>我们熟悉的栈</h3>
<p>栈是什么应该都很熟悉了，就是一个FILO的数据结构，不过他是用来干啥的呢？当然，他可以用来以各种奇怪的方式来遍历一棵树，不过他在操作系统里主要还是为各种函数调用，中断异常处理之类的东西保存跳转前程序运行的局部信息，使得这些跳转在完成后，程序可以恢复到原先的执行位置。具体情况就在下个图说明了，能把这个图讲清楚我就功德圆满了。</p>
<img src="http://lh4.googleusercontent.com/-u6RsUf4DQ_I/T9bhTfScysI/AAAAAAAAARw/pGDLpfXjilM/s512/stack1.jpg" alt="" style="float:none;">
<p>这个图从哪说起呢？先从左边的两个指针说起吧。ebp是桢指针，其实我觉的叫桢底指针更容易理解一点，因为它指向的其实就是当前函数运行空间的桢底；esp是栈指针，指向了栈顶，ebp和esp的空间范围就是当前函数内存占据的空间又叫一个桢。然后就说说这个桢里有什么家当，首先是一个保存的ebp，它保存的是什么东西呢？它存着调用这个函数的函数的桢指针，比如说函数a调用函数b，那么在b的桢里面首先会存着a的ebp，这样当b返回时，推栈的时候就可以把a的ebp恢复回去。esp这个栈顶指针可以用来标志变量应该在那个位置进栈还是出栈，那ebp这个栈底指针又有什么用呢？如果你写一个C语言函数用GCC翻译成汇编代码就会发现所有局部变量的地址都是由ebp减一个偏移量计算出来的，ebp相当于提供一个基地址。为什么不用esp做基地址动动脑字想想就好了，为什么要减看看图最右边那个箭头就明白了。再往下是寄存器保存区域，按照IA32的惯例，ebx，esi和edi三个寄存器如果当前函数需要覆盖的话，要把他们保存，这个区域就是来保存寄存器的。再往下就是存当前函数的局部变量，临时变量之类的东西。再往下那个参数构造区域我就不知道是干啥的了，求大牛指点。</p>
<p>ebp往上是调用者桢，首先是个返回地址，这样函数调用再返回时就知道pc应该填多少了，然后是n个参数，稍微注意一下这些参数是按从右到左入栈的。如果函数在运行的时候要用这些参数改怎么办呢，因为ebp已经不指向保存参数那个函数的桢了，没有办法用ebp减去一个偏移量来找到位置了。其实从图上很容易看出来，用ebp加一个偏移量就可以索引了。</p>
<p>再往上就是其他的桢了，而这些所有的桢构成了进程的栈空间。每当调用一个函数时保存当前ebp，这时候esp会自动增长，再将ebp指向esp指向的位置，一个新的桢就建立了，再根据函数的变量情况，esp再继续生长。函数返回时从当前ebp指向的内存位置恢复，pc恢复成返回值，esp动态减少。栈就是这么生长和收缩的。</p>
<h3>堆又是什么东西</h3>
<p>先插个故事，当年去百度面试，大师觉得我实在是什么都不懂，就随口问了我一句堆和栈有什么区别，我说堆要用malloc分配，然后就混过去了……这其实还是在之前忘了去哪家公司笔试的时候有道问怎么在堆上建立一个数组我不会做，回去查出来的。这也是我一直想写这篇博客的原因，不过堆这块最后还是有很多不懂的。</p>
<p>先说一下为什么要有堆，之前的栈的结构貌似很完美了，可以动态伸缩，层层调用，为什么还要有堆呢？想一下全局变量该怎么引用呢？这时候ebp也是变化的了，怎么才能找到那个绝对的位置呢？在每个桢里面都复制一份全局变量？或者通过栈底地址来计算？（其实我觉得这个方案单进程貌似还可以，如果多线程的话每个线程都会有一个栈就又不行了）另一方面，桢空间的大小分配是在函数调用发生的时候就确定的，有多少变量占多少空间就分配多大。不过就像刚才那个故事，世界上存在一个叫malloc的函数，而它分配的空间是不固定的，也就无法在栈里为它分配空间。如果非要强行分配的话，那么怎么通过ebp来确定每个变量的位置呢？另外操作系统为每个栈分配的最大空间是有限的，无法随意增长。</p>
<p>所以为了克服这个问题就有了堆这个东西。在数据结构的概念里里堆是一个特殊的树状结构，不过在程序调用这个范围里堆是个简单的双向链表，将空闲的内存空间串起来，每当需要分配的时候就从链表中取下一块进行分配，在桢区只要保存一个指向这个位置的指针就可以了。另外在分配的时候还会在分配空间的第一块里存下分配内存的大小，这也是为什么当我们使用delete或者free这类函数不许要指定空间大小的原因。</p>
<p>堆的工作原理真的好难找，书上讲得也语焉不详，上网搜给我蹦出来好几个核反应堆工作原理。大致说一下，进程中有一个空闲内存链表，每当mallco的时候就顺着这个表找到一第一块大于等于分配空间要求的截断下来，把剩下的空间继续链起来。当free的时候就直接再把这块空间给挂到链表尾部，这样时间长的话碎片就会很严重，可能找不到大小合适的空闲块，这时候malloc会开始进行整理合并一些相邻块。</p>
<h2>栈溢出及攻击</h2>
<p>好了下面开始启动攻击模式，看看怎么把程序整崩溃。</p>
<p>记得栈里面存着什么不？有定位变量的ebp，它要坏了变量就找不到了，有返回地址，它要坏了函数返回就错了。问题是怎么让他坏呢？这就要用到溢出了，这种攻击相对简单，举个栗子就懂了。</p>
<img src="http://lh6.googleusercontent.com/-vA2mRdi04D0/T9b5zQQOknI/AAAAAAAAASA/C2yvLFz2l6E/s366/stack2.jpg" alt="">
<p>这个图是一个简单的函数桢，局部变量是个char型的数组buf[4]。然后在C语言里给char数组用gets函数赋值，因为gets是不检查赋值长度的，我们就赋100个字符给buf。根据之前讲过的东西，buf通过ebp定位buf的首地址为ebp-4。然后第一个到第四个字符顺利复制到buf+0，buf+1，buf+2，buf+3这四个位置。从第五个开始，事情开始起变化，5~8四个字符会复制到buf+4，buf+5，buf+6，buf+7，把保存的ebp给破坏，这样当函数返回后ebp就无法恢复到调用者的桢底，对变量和参数的定位都回发生错误。再往后四个字符把返回地址也覆盖了这样函数就不能返回到正常的程序流了，再往后，函数的参数也被破坏了，再往后上一个桢的局部变量也被破坏了。</p>
<p>通过大量的非法输入来破坏之前的程序数据，这就是溢出的基本思路。然后很多心地善良的人就利用这个方法对程序进行攻击。由于返回值是可以更改的，这些心地善良的人就可以插入很长的一段非法输入，在里面包含一段自己写的善良的代码，这段代码也会覆盖的栈上，如果能把返回地址改成这段善良代码的首地址，善良的人们就可以成功的做他们相要做的事情了。当然说着简单具体怎么算出合适的地址和如写出一段有用的汇编代码还是颇费心思的，不过通往自由之门大致就是这个样子的。</p>
<p>当然也有一股黑暗的势力相要阻挡这些人通往自由的道路设置了种种障碍，现在流行的方法主要有三种。第一种就是在每个桢首部随机插入一定的空间，这些空间唯一的作用就是让你不知道该怎么计算你的善良代码的位置和返回地址的位置。第二种是在函数返回的时候检查桢结构是否被破坏，具体实现方法是在桢上存一个变量，在函数返回的时候检查这个值是否被更改，这个方法还有个邪恶的名字叫金丝雀法。第三种方法是限制栈的权限，栈只有读和写的能力，没有执行的能力，这样恶意代码就被摁在那里不能动了。</p>
<p>然后我研究了一下参考资料里的小册子，发现善良的人们已经找到通往自由的新道路了，任何黑暗势力终究是要败下阵来的。</p>
<h2>堆溢出</h2>
<p>这块那本善良人手册写得实在是太晦涩了，我实在是没看懂，求信安大牛拯救。</p>
<p>大致思路是这样的，malloc分配出来的空间也是存着一个元数据的东西，分配块的大小，另一说是前一个空闲块地址，看得我迷迷糊糊的，姑且按大小来理解。当采用和栈溢出相同的入侵方法输入大量数据的时候，这块元数据的信息也会被破坏。如果把元数据改成负数的话，那么free的时候就会异常，如果改成个别的数，在malloc的时候可能会分配到已分配的空间造成重叠，balabala一堆破事。</p>
<p>然后那本善良人手册上还列举了各种攻击方法，什么伪造空闲块，转移到桢栈空间之类的匪夷所思的方法，总之通过披荆斩棘，善良的人类又一次发现了光明。</p>
<h2>参考资料</h2>
<ul><a href="http://book.douban.com/subject/2702069/">The Shellcoder's Handbook</a> 善良人手册</ul>
<ul><a href="http://book.douban.com/subject/5333562/">深入理解计算机系统</a></ul>
<ul><a href="http://book.douban.com/subject/2287506/">深入理解Linux内核</a></ul>
