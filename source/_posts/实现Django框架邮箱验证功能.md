---
title: 实现Django框架邮箱验证功能
date: 2018-05-24 17:46:10
tags: Django
categories: web
comments: true
description: 填写用户邮箱，保存，然后发送验证邮件，用户验证邮箱，跳转回页面
---
Django框架中，实现用户中心页面的设置邮箱功能，并根据用户设置的邮箱，发送验证邮箱，用户通过点击验证地址，完成邮箱验证。

### 用户表添加字段
在用户的user表中添加字段，代表该用户使用的邮箱是否通过验证，true为通过验证，相反为false。
``` javascript
email_active = models.BooleanField(default=False, verbose_name='邮箱验证状态')
```
然后进行数据库迁移，完成字段创建。

### 保存用户邮箱，并发送验证邮箱
用户根据页面输入框输入邮箱后，点击保存，将用户输入的邮箱验证，并保存到数据库user表中，然后根据这个地址，发送验证邮件。

#### 定义序列化器
继承自modelserializer
``` javascript
class EmailSerializer(serializers.ModelSerializer):
    """
    邮箱序列化器
    """
    # 指定模型类，属性
    class Meta:
        model = User
        fields = ('id', 'email')
        extra_kwargs = {
            'email': {
			# 验证邮箱为必填字段
                'required': True
            }
       }
	   # 重写update方法，数据库修改该用户的邮箱
		def update(self, instance, validated_data):
        # 从请求体中接收数据，后面向这个邮箱发送邮件
        email = validated_data['email']
        # instance要序列化的对象，即user，给email属性赋值
        instance.email = validated_data['email']
        # 提交
        instance.save()
```

#### 定义保存的视图类
因为不是根据用户id来修改邮箱，而是根据当前登录的用户，所以不传pk，而是重写get_object方法，来获取当前登录的对象
``` javascript
class SaveEmail(UpdateAPIView):
    # 验证用户是否登陆，Drf提供的验证功能
    permission_classes = [IsAuthenticated]
    # 指定序列化器
    serializer_class = EmailSerializer
    # 因为不获取ｐｋ，所以保存的时候获取当前登陆用户的对象
    def get_object(self):
        # 将对象存到ｒｅｑｕｅｓｔ里
        return self.request.user
```
然后配置url即可。

#### 生成验证地址
保存用户输入的邮箱之后，向这个邮箱发送验证地址，首先需要生成验证地址。
在user的models里添加方法，实现生成地址的功能，在拼接地址时要经过加密，导入jwt，使用jwt加密

``` javascript
# 定义生成地址的方法
    def generate_verify_email_url(self):
        """
        生成验证邮箱的url
        """
        # 设置itsdangerous加密
        serializer = TJWSSerializer(settings.SECRET_KEY, expires_in=constants.VERIFY_EMAIL_TOKEN_EXPIRES)
        data = {'user_id': self.id, 'email': self.email}
        token = serializer.dumps(data).decode()
        verify_url = 'http://域名/success_verify_email.html?token=' + token
        # 返回生成的地址
        return verify_url
```
然后在序列化器 EmailSerializer下的update方法下添加代码：

``` javascript
 # 生成验证链接，调用生成验证连接的函数
        verify_url = instance.generate_verify_email_url()
```
接收生成后的url地址

#### 向用户的邮箱发送验证地址
发送邮箱，属于等待耗时操作，所以使用Celery异步服务（详情看：[点这里](https://zypuu.github.io/2018/08/20/%E5%85%B3%E4%BA%8ECelery%E7%9A%84%E5%BC%82%E6%AD%A5%E6%9C%8D%E5%8A%A1%E4%BD%BF%E7%94%A8/)）
在celery_tasks下新建包email，在包里新建文件tasks.py,然后在main.py里添加`'celery_tasks.email',`
在tasks文件里添加任务代码如下：

``` javascript
from celery_tasks.main import app
from django.core.mail import send_mail
from django.conf import settings

@app.task(name='send_verify_email')
def send_verify_email(to_email, verify_url):
    """
    发送验证邮箱邮件
    :param to_email: 收件人邮箱
    :param verify_url: 验证链接
    :return: None
    """
    subject = "邮件标题（例：***邮箱验证）"
    html_message = '<p>尊敬的用户您好！</p>' \
                   '<p>感谢您使用*****。</p>' \
                   '<p>您的邮箱为：%s 。请点击此链接激活您的邮箱：</p>' \
                   '<p><a href="%s">%s<a></p>' % (to_email, verify_url, verify_url)
	# Django自带的发送邮件功能 
    send_mail(subject, "", settings.EMAIL_FROM, [to_email], html_message=html_message)
```
然后在序列化器 EmailSerializer下的update方法下添加代码：

``` javascript
 # 发送验证邮件，邮箱，与验证连接作为参数
        # 使用celery异步服务发送验证，在tasks里面
        send_verify_email.delay(email, verify_url)
        # 最后，经过保存，接收验证地址，发送地址等功能后，返回该对象
        return instance
```
到此发送验证邮件完成

#### 技术补充点：Django发送邮件
首先注册一个专门用来发送邮件的邮箱163,126，qq等，然后在这些邮箱配置SMTP服务器（设置中开启，经过手机验证后会收到授权码的短信，然后填写授权码，开启。详情可百度）

然后在配置中添加代码：

``` javascript
EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'
EMAIL_HOST = 'smtp.163.com' # （163为例）
EMAIL_PORT = 25
#发送邮件的邮箱
EMAIL_HOST_USER = '你的账号'
#在邮箱中设置的客户端授权密码
EMAIL_HOST_PASSWORD = '你的授权密码'
#收件人看到的发件人
EMAIL_FROM = '<你的邮箱>'
```
使用django发送邮件：

在django.core.mail模块提供了send_mail来发送邮件。

``` javascript
在django.core.mail模块提供了send_mail来发送邮件。

send_mail(subject, message, from_email, recipient_list,html_message=None)
# 各个参数的含义
	subject 邮件标题
	message 普通邮件正文， 普通字符串
	from_email 发件人
	recipient_list 收件人列表
	html_message 多媒体邮件正文，可以是html字符串可以呈现html页面
```

### 验证邮箱
用户在邮箱收到验证邮件后，点击地址进行验证，验证成功返回用户中心页面。

#### 设置解密

因为生成的验证邮箱地址时带有itsdangerous加密的token的，所以要先解密，在user的models里添加解密方法，代码如下：

``` javascript
# 设置解密方法
    @staticmethod
    def check_verify_email_token(token):
        """
        检查验证邮件的token
        """
        # 解密
        serializer = TJWSSerializer(settings.SECRET_KEY, expires_in=constants.VERIFY_EMAIL_TOKEN_EXPIRES)
        try:
            data = serializer.loads(token)
        except BadData:
            return None
        else:
            # 解密之后，获取data里面的数据
            email = data.get('email')
            user_id = data.get('user_id')
            try:
                # 根据数据，获取对象
                user = User.objects.get(id=user_id, email=email)
            except User.DoesNotExist:
                return None
            else:
                # 返回对象
                return user
```

然后新建constants.py常量文件，然后添加代码：

``` javascript
VERIFY_EMAIL_TOKEN_EXPIRES=60*60*24
```
设置过期时间。

#### 定义视图函数

``` javascript
class SendEmail(APIView):
    def get(self, request):
        # 获取token，由jwt签发的token，在查询参数里，获取查询参数
        token = request.query_params.get('token')
        if not token:
            # 如果没有token，则返回信息，与状态码
            return Response({'message': '缺少token'}, status=status.HTTP_400_BAD_REQUEST)
        # 验证过程
        # 取得token后验证token，解密，确定是否被更改
        # 接收解密后返回的对象
        user = User.check_verify_email_token(token)
        if user is None:
            return Response({'message': '链接信息无效'}, status=status.HTTP_400_BAD_REQUEST)
        else:
            # 没被更改即验证成功
            # 数据库在邮箱验证的通过字段添加信息
            user.email_active = True
            # 提交保存
            user.save()
            return Response({'message': 'OK'})
```
由前端代码收到这个return后，跳转回用户页面即可。



