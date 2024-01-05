---
title: DJANGO框架如何实现用户多认证方式登录与第三方授权登录
date: 2018-06-11 19:38:20
tags: web,Django
categories: web开发
comments: true
description: 登录时单用户支持多种方式登录，添加第三方授权登录，腾讯qq为例
---

## 多种认证方式登录
Django框架提供了认证系统，详情看文档[Django认证系统官方文档](https://yiyibooks.cn/xx/Django_1.11.6/topics/auth/index.html)

在这个认证系统中，有一个用户认证的方法authenticate（）来验证一组凭据，默认的是username和password，官方调用源码如下：

``` javascrip
from django.contrib.auth import authenticate
user = authenticate(username='john', password='secret')
if user is not None:
    # A backend authenticated the credentials
else:
    # No backend authenticated the credentials
```
所以只需要重写这个方法，就可以实现多凭证登录。
方法如下：
1.在user应用下新建utils.py文件
2.定义类继承Modelbackend，重写authenticate方法
3.重写规则，代码如下

``` javascript
# 重写authenticate方法，继承ModelBackend这个类来重写方法
from django.contrib.auth.backends import ModelBackend
from .models import User
class UserModelBackend(ModelBackend):
    def authenticate(self, request, username=None, password=None, **kwargs):
        # 判断用户输入的是手机号还是用户名
        try:
            # 查询对象，如果能查到对象则得到返回的对象
            user = User.objects.filter(mobile=username)
            # 如果不是手机用户，则执行except
        except:
            # 判断是否用户名，与用户名对比
            try: 
                user = User.objects.filter(username=username)
            except:
                # 都不是返回空
                return None
        # 如果查询到用户对象，则检查密码
        if user.check_password(password):
            return user
        return None
```
4.配置中设置，settings中添加

``` javascript
AUTHENTICATION_BACKENDS=[
			'users.utils.UsernameMobileModelBackend',
		]
```
即可实现使用用户手机号登录。

## 授权第三方登录（QQ为例）
QQ登录，即第三方登录，用户不在本网站输入账户密码，由第三方授权验证就可以登录本网站。如何实现授权qq登录呢，步骤如下：

### 第一步：QQ互联开发者注册
要想实现第三方QQ登录，需要成为QQ互联的开发者，通过审核后，方可继续下面的步骤，注册参考文档：[看这里](http://wiki.connect.qq.com/%E6%88%90%E4%B8%BA%E5%BC%80%E5%8F%91%E8%80%85)
登录成功后，填写注册信息，如下图所示
![1](1.jpg)
注册成功即可。
### 第二步：创建应用
注册成功后要创建应用，选择创建网站应用还是移动应用，并填写相关资料进行创建。
如图所示点击创建应用。
![2](2.jpg)
填写相关资料
![3](3.jpg)
回调地址与备案信息要写规范
![4](4.jpg)
最后创建成功，如图所示
![5](5.jpg)
网站应用创建完成，点击“应用管理”，进入管理中心，在管理中心可以查看到网站获取的appid和appkey，如下图所示：
![6](6.jpg)
记住这两条数据，后面会用到。

### 第三步：设置QQ登录按钮（前端代码）
按钮的图标样式，还有前端ui规范，以及示例代码，均在官方文档里有详细介绍，这里就不说了，主要是后端代码的开发
设置QQ登录按钮：[点这里](http://wiki.connect.qq.com/%E6%94%BE%E7%BD%AEqq%E7%99%BB%E5%BD%95%E6%8C%89%E9%92%AE_oauth2-0)

### 第四步：网站后端代码开发
由于后端代码开发流程比较复杂，首先梳理一下授权QQ登录的流程图
#### 使用QQ登录的流程
如图所示
![7](7.jpg)
由流程可见，后端代码开发需要创建三个视图，下面进行代码实现。

#### 配置中添加QQ开发者信息
在settings.py文件中添加如下代码：

``` javascript
# QQ登录参数
QQ_CLIENT_ID = '你的APPID'
QQ_CLIENT_SECRET = ‘你的APPKEY’
QQ_REDIRECT_URI = '网站回调网址'
QQ_STATE = '/' # 默认state初始网址为根目录
```

#### 新建应用、创建模型类
在项目目录下的utils文件包内新建models.py（没有utils先建utils），里面添加如下代码：

``` javascript
from django.db import models
# 创建模型类基类，用于增加数据新建时间和更新时间。
class BaseModel(models.Model):
    """为模型类补充字段"""
    create_time = models.DateTimeField(auto_now_add=True, verbose_name="创建时间")
    update_time = models.DateTimeField(auto_now=True, verbose_name="更新时间")

    class Meta:
        abstract = True  # 说明是抽象模型类, 用于继承使用，数据库迁移时不会创建BaseModel的表
```
然后新建应用oauth，配置url与根目录url，在oauth的models里添加如下代码：

``` javascript
from django.db import models
from 根目录.utils.models import BaseModel
# 新建模型类，user与openid的关联表
class OAuthQQUser(BaseModel):
    """
    QQ登录用户数据
    """
	# 定义user，openid字段
    user = models.ForeignKey('users.User', on_delete=models.CASCADE, verbose_name='用户')
    openid = models.CharField(max_length=64, verbose_name='openid', db_index=True)

    class Meta:
	# 表名，与字段后台显示名
        db_table = 'tb_oauth_qq'
        verbose_name = 'QQ登录用户数据'
        verbose_name_plural = verbose_name
```
然后进行数据库迁移，终端命令如下：

``` javascript
python manage.py makemigrations
python manage.py migrate
```
未来会有很多第三方账户集成登录，所以新建应用oauth
并不修改原有表结构，而是新建表，完成第三方登录
好处：
1.不影响原有操作
2. 未来会实现多种登录的可能性，提供出更方便的扩展方案：新建表

#### 创建qq登录辅助工具
在oauth应用下新建utils.py文件，在该文件下添加如下代码：

``` javascript
from urllib.parse import urlencode, parse_qs
from urllib.request import urlopen
from itsdangerous import TimedJSONWebSignatureSerializer as Serializer, BadData
from django.conf import settings
import json
import logging

from . import constants

logger = logging.getLogger('django')


class OAuthQQ(object):
    """
    QQ认证辅助工具类
    """
	# 初始化属性，接收四个参数，客户的appid，appkey，回调地址，初始跳转页面
    def __init__(self, client_id=None, client_secret=None, redirect_uri=None, state=None):
	# or：代表if not ，如果接收到参数值，就是用接收的，如果接收none，就用配置的
        self.client_id = client_id or settings.QQ_CLIENT_ID
        self.client_secret = client_secret or settings.QQ_CLIENT_SECRET
        self.redirect_uri = redirect_uri or settings.QQ_REDIRECT_URI
        self.state = state or settings.QQ_STATE  # 用于保存登录成功后的跳转页面路径
	
	# 定义生成url登录地址的函数，返回登录页面url的函数
    def get_qq_login_url(self):
        """
        获取qq登录的网址
        :return: url网址
        """
        params = {
            'response_type': 'code',
            'client_id': self.client_id,
            'redirect_uri': self.redirect_uri,
            'state': self.state,
            'scope': 'get_user_info',
        }
        url = 'https://graph.qq.com/oauth2.0/authorize?' + urlencode(params)
        return url
```

#### 补充技术点1：urllib

``` javascript
urllib.parse.urlencode(query)
```
将query字典转换为url路径中的查询字符串

``` javascript
urllib.parse.parse_qs(qs)
```
将qs查询字符串格式数据转换为python的字典

``` javascript
urllib.request.urlopen(url, data=None)
```
发送http请求，如果data为None，发送GET请求，如果data不为None，发送POST请求

返回response响应对象，可以通过read()读取响应体数据，需要注意读取出的响应体数据为bytes类型


#### 创建第一个视图函数
配置第一个视图函数的url：url(r'^qq/authorization/$', views.QQAuthURLView.as_view())
``` javascript
class QQAuthURLView(APIView):
    """
    获取QQ登录的url
    """
    def get(self, request):
        """
        提供用于qq登录的url
        """
		# 获取next的地址，即登陆成功后返回之前浏览的页面
        next = request.query_params.get('next')
		# OAuthQQ是辅助工具的类，创建对象将next赋值给state初始状态的页面
        oauth = OAuthQQ(state=next)
		# 调用辅助工具的get_qq_login_url函数得到url
        login_url = oauth.get_qq_login_url()
		# 返回URL地址
        return Response({'login_url': login_url})
```
到此第一步完成，即返回用户的登录页面，接下里用户进行授权登录
#### 第二个视图函数
即用户登陆后，获取登录数据code，然后根据code，去获取accesstoken与openid
代码如下：

``` javascript
class QQAuthUserView(APIView):
    """
    QQ登录的用户
    """
    def get(self, request):
        """
        获取qq登录的用户数据
        """
		# 从请求地址的查询参数中获取code
        code = request.query_params.get('code')
		# 没有code抛出异常
        if not code:
            return Response({'message': '缺少code'}, status=status.HTTP_400_BAD_REQUEST)
		# 创建oauth对象，类来自定义的qq登录辅助工具
        oauth = OAuthQQ()

        # 获取用户openid
        try:
		# 通过code获取token
            access_token = oauth.get_access_token(code)
			# 通过token获取openid
            openid = oauth.get_openid(access_token)
			# 没有获取到的话抛出异常
        except QQAPIError:
            return Response({'message': 'QQ服务异常'}, status=status.HTTP_503_SERVICE_UNAVAILABLE)

        # 判断用户是否存在
        try:
		# 通过openid查询用户，创建的关联表里
            qq_user = OAuthQQUser.objects.get(openid=openid)
        except OAuthQQUser.DoesNotExist:
            # 用户第一次使用QQ登录，显示绑定界面
            token = oauth.generate_save_user_token(openid)
            return Response({'access_token': token})
        else:
            # 找到用户，认为登录成功， 生成jwt_token
            user = qq_user.user
            jwt_payload_handler = api_settings.JWT_PAYLOAD_HANDLER
            jwt_encode_handler = api_settings.JWT_ENCODE_HANDLER

            payload = jwt_payload_handler(user)
            token = jwt_encode_handler(payload)
			# 响应返回
            response = Response({
                'token': token,
                'user_id': user.id,
                'username': user.username
            })
            return response
```

#### QQ辅助工具中添加代码

``` javascript
def get_access_token(self, code):
        """
        获取access_token
        :param code: qq提供的code
        :return: access_token
        """
     	# 1.构造参数
        params = {
            'grant_type': 'authorization_code',
            'client_id': self.client_id,
            'client_secret': self.client_secret,
            'code': code,
            'redirect_uri': self.redirect_uri
        }
        # 2.发起http请求，请求qq服务器
        url = 'https://graph.qq.com/oauth2.0/token?' + urlencode(params)
        response = urlopen(url)
        # 3.接收响应数据，解码
        response_data = response.read().decode()
        # access_token=**&expires_in=**&refresh_token=**
		转成python字典
        data = parse_qs(response_data)
        # 4.从字典中获取token
        access_token = data.get('access_token', None)
		# 如果没有token，写日志抛出异常
        if not access_token:
            logger.error('code=%s msg=%s' % (data.get('code'), data.get('msg')))
            raise QQAPIError
        # 取出accesstoken的值的列表的第一个元素
        return access_token[0]

    def get_openid(self, access_token):
        """
        获取用户的openid
        :param access_token: qq提供的access_token
        :return: open_id
        """
		# 发起qq服务器请求
        url = 'https://graph.qq.com/oauth2.0/me?access_token=' + access_token
        response = urlopen(url)
		# 返回数据二进制解码
        response_data = response.read().decode()
        try:
        # 返回的数据 callback( {"client_id":"YOUR_APPID","openid":"YOUR_OPENID"} )\n;cogn
			# 将字符串转成字典
            data = json.loads(response_data[10:-4])
        except Exception:
			# 没获取到抛出异常
            data = parse_qs(response_data)
            logger.error('code=%s msg=%s' % (data.get('code'), data.get('msg')))
            raise QQAPIError
		# 从字典中获取数据
        openid = data.get('openid', None)
        return openid
		
# 将返回的openid通过itsdangerous加密，然后返回token，发送这个token
	@staticmethod
    def generate_save_user_token(openid):
        """
        生成保存用户数据的token
        :param openid: 用户的openid
        :return: token
        """
        serializer = Serializer(settings.SECRET_KEY, expires_in=constants.SAVE_QQ_USER_TOKEN_EXPIRES)
        data = {'openid': openid}
        token = serializer.dumps(data)
        return token.decode()
		
	# 加载读取接收到的token，解密，获取openid
    @staticmethod
    def check_save_user_token(token):
        """
        检验保存用户数据的token
        :param token: token
        :return: openid or None
        """
        serializer = Serializer(settings.SECRET_KEY, expires_in=constants.SAVE_QQ_USER_TOKEN_EXPIRES)
        try:
            data = serializer.loads(token)
        except BadData:
            return None
        else:
            return data.get('openid')
```
以上第二步完成，获取到openid，并对用户是否第一次登录，是否需要绑定进行了判断，如果用户是第一次登录，需要绑定，则转到绑定页面，执行第三步。

#### 补充技术点2：itsdangerous
官方文档：[点这里](http://itsdangerous.readthedocs.io/en/latest/)
itsdangerous是一种加密签名方式，可以通过秘钥加密，也可以通过秘钥解密
确保自己的数据在返回时没有经过别人的篡改，保证数据传输的安全性
安装：`pip install itsdangerous`
使用：以时间戳为例

``` javascript
from itsdangerous import TimedJSONWebSignatureSerializer as Serializer
from django.conf import settings

# serializer = Serializer(秘钥, 有效期秒)
serializer = Serializer(settings.SECRET_KEY, 300)
# serializer.dumps(数据), 返回bytes类型，加密数据
token = serializer.dumps({'mobile': '18512345678'})
token = token.decode()

# 检验token
# 验证失败，会抛出itsdangerous.BadData异常
serializer = Serializer(settings.SECRET_KEY, 300)
try:
# 加载token数据，解密数据
    data = serializer.loads(token)
except BadData:
    return None
```


#### 第三个视图函数
视图代码如下：
因为是绑定数据库增加数据，所以在第二个视图函数中继续定义post方法即可，不用单独创建视图类，该视图实现用户绑定的方法
``` javascript
def post(self,request):
		# 指定序列化器
        serializer = OAuthQQUserSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()

        response = Response({
            'token': user.token,
            'user_id': user.id,
            'username': user.username
        })
        return response
```
定义序列器

``` javascript
class OAuthQQUserSerializer(serializers.ModelSerializer):
    """
    保存QQ用户序列化器
    """
	# 添加字段
    sms_code = serializers.CharField(label='短信验证码', write_only=True)
    access_token = serializers.CharField(label='操作凭证', write_only=True)
    token = serializers.CharField(read_only=True)
    mobile = serializers.RegexField(label='手机号', regex=r'^1[3-9]\d{9}$')

    class Meta:
        model = User
        fields = ('mobile', 'password', 'sms_code', 'access_token', 'id', 'username', 'token')
        extra_kwargs = {
            'username': {
                'read_only': True
            },
            'password': {
                'write_only': True,
                'min_length': 8,
                'max_length': 20,
                'error_messages': {
                    'min_length': '仅允许8-20个字符的密码',
                    'max_length': '仅允许8-20个字符的密码',
                }
            }
        }
	# 验证
    def validate(self, attrs):
        # 检验access_token，获取加密的token值
        access_token = attrs['access_token']
		# 解密
        openid = OAuthQQ.check_save_user_token(access_token)
        if not openid:
            raise serializers.ValidationError('无效的access_token')

        attrs['openid'] = openid

        # 检验短信验证码
        mobile = attrs['mobile']
        sms_code = attrs['sms_code']
        redis_conn = get_redis_connection('verify_code')
        real_sms_code = redis_conn.get('sms_code_%s' % mobile)
        if real_sms_code.decode() != sms_code:
            raise serializers.ValidationError('短信验证码错误')

        # 如果用户存在，检查用户密码
        try:
            user = User.objects.get(mobile=mobile)
        except User.DoesNotExist:
            pass
        else:
            password = attrs['password']
            if not user.check_password(password):
                raise serializers.ValidationError('密码错误')
				# attrs中添加user数据
            attrs['user'] = user
        return attrs

    def create(self, validated_data):
        openid = validated_data['openid']
        user = validated_data.get('user')
        mobile = validated_data['mobile']
        password = validated_data['password']
		# 获取user
        if not user:
            # 如果用户不存在，创建用户，绑定openid（创建了OAuthQQUser数据）
            user = User.objects.create_user(username=mobile, mobile=mobile, password=password)
		# 在用户与openid中的关联表中添加数据
        OAuthQQUser.objects.create(user=user, openid=openid)

        # 签发jwt token
        jwt_payload_handler = api_settings.JWT_PAYLOAD_HANDLER
        jwt_encode_handler = api_settings.JWT_ENCODE_HANDLER

        payload = jwt_payload_handler(user)
        token = jwt_encode_handler(payload)

        user.token = token

        return user
```
到此，可实现授权QQ第三方登录的功能
