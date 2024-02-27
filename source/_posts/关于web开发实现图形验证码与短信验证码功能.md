---
layout: “gnew
title: 关于web开发用户注册功能的图形验证码与短信验证码
date: 2018-06-18 19:15:15
tags: 验证码
categories: web
comments: true
description: 基于Flask框架与Django框架的web开发过程中，用户注册功能如何实现图形验证码与短信验证码功能
---

## Flask框架
<div>前后端不分离</div>

### 图片验证码

#### Captcha

<div>1.基于captcha实现图片验证码，什么是captcha？<br>
Captcha是一个第三方工具，提供生成验证码图片通用解决办法，提供了非常灵活的生成验证码图片的框架，可以自由的组合生成图片过程中的各种元素，例如，字体、颜色、背景、扭曲样式等，不仅提供了丰富的变形资源，即使不能满足需求的情况下，也可以实现固有的接口，创造出自己的字体变形的方式，所以该框架应该可以满足生成验证图片的大部分需求。<br>

#### Flask框架中使用captcha完成图片验证码功能<br>

将chptcha的第三方包放在utils文件夹中，utils是基于python创建一个flask工程后一个专门存放第三方工具包的文件夹。然后在功能视图模块中</div>

``` javascript
from utils.captcha.captcha import captcha
```
视图函数中

``` javascript
# @user_blueprint是flask框架中，经过创建蓝图，蓝图注册的路由，后面是路由地址
@user_blueprint.route('/image_code')
def image_code():
    # 调用第三方的工具，生成图形验证码数据
    name, text, image = captcha.generate_captcha()
    # 保存text值，存放于session中，用于后续的对比验证
    session['image_code'] = text
 
    # 创建响应对象，响应体为图片数据
    response = make_response(image)
    # 注意：这里一定要设置响应数据的类型为图片，不然会在网页上无法显示，生成乱码数据
    response.content_type = 'image/png'
    # 返回到响应体
    return response
```
在首页的页面中index.html中，添加如下代码：

``` javascript
<img src="/user/image_code?1" class="get_pic_code" onclick="generateImageCode()">
```
显示图片，设置css样式，并绑定点击事件，生成图片验证码
然后在main.js（主页js里）添加：

``` javascript
function generateImageCode() {
    $('.get_pic_code').attr('src', $('.get_pic_code').attr('src') + '1');
}
```
点击事件，点击即修改他的src属性，重新生成图片验证码，即可实现
$('.get_pic_code')是类选择器，attr获取其src属性进行修改

### 短信验证码

#### 容联云通讯
容联云通讯为第三方服务，云通讯平台将传统电信网络通讯能力、基于IP的通讯能力，通过开放API的方式提供给开发者与合作伙伴，让开发者们在应用程序中集成网络电话和电话会议功能变得简单。<br>
可提供语音、IVR、短信、IM、视频等web开发接口，这里使用短信功能，详情可查看官方开发文档[点这里](http://doc.yuntongxun.com/space/5a5098313b8496dd00dcdd7f)
查看基于python的短信发送接口。

#### 实现短信验证码发送功能
将云通讯第三方工具包放入utils文件夹中，云通讯文档使用说明：
1.接口声明文件：SDK \CCPRestSDK.py

2.接口函数定义：def sendTemplateSMS(self, to,datas,tempId) 

3.参数说明：

to: 短信接收手机号码集合,用英文逗号分开,如 '13810001000,13810011001',最多一次发送200个。

datas：内容数据，需定义成数组方式，如模板中有两个参数，定义方式为array['Marry','Alon']。 

templateId: 模板Id,如使用测试模板，模板id为"1"，如使用自己创建的模板，则使用自己创建的短信模板id即可。
4.接口调用示例：

``` javascript
编码说明：coding=utf-8或gbk
 from CCPRestSDK import REST
 import ConfigParser
 
 accountSid= '您的主账号'; 
 #说明：主账号，登陆云通讯网站后，可在控制台首页中看到开发者主账号ACCOUNT SID。
 
 accountToken= '您的主账号Token'; 
 #说明：主账号Token，登陆云通讯网站后，可在控制台首页中看到开发者主账号AUTH TOKEN。
 
 appId='您的应用ID'; 
 #请使用管理控制台中已创建应用的APPID。
 
 serverIP='app.cloopen.com';
 #说明：请求地址，生产环境配置成app.cloopen.com。
 
 serverPort='8883'; 
 #说明：请求端口 ，生产环境为8883.
 
 softVersion='2013-12-26'; #说明：REST API版本号保持不变。 
 
 def sendTemplateSMS(to,datas,tempId): 
    #初始化REST SDK
    rest = REST(serverIP,serverPort,softVersion) 
    rest.setAccount(accountSid,accountToken) 
    rest.setAppId(appId)
 
    result = rest.sendTemplateSMS(to,datas,tempId) 
    for k,v in result.iteritems():
        if k=='templateSMS' : 
                for k,s in v.iteritems():
                    print '%s:%s' % (k, s) 
        else: 
            print '%s:%s' % (k, v) 
```
在视图函数中定义如下视图：

``` javascript
# 蓝图注册
@user_blueprint.route('/sms_code')
def sms_code():
    # 接收:手机号，图形验证码，从请求报文中接收
    mobile = request.args.get('mobile')
    imagecode = request.args.get('imagecode')

    # 验证
    # 1.值必填  空在python中为False
    # 如果都不为空
    if not all([mobile, imagecode]):
        # 返回json数据格式，由前端代码进一步处理
        return jsonify(result=1)
 
    # 2.检验图形验证码一致，之前图形验证码已经存在session中
    imagecode_session = session.get('image_code')
    if not imagecode_session:
        return jsonify(result=4)
    # 删除session中的数据，强制图形验证码过期，防止客户端不停尝试
    del session['image_code']
	# 验证码不对的情况
    if imagecode != imagecode_session:
        return jsonify(result=2)

    # 处理
    # 1.通过random随机数生成随机的验证码
    smscode = str(random.randint(100000, 999999))
    # 2.保存验证码，用于后续验证，存到session中
    session['sms_code'] = smscode
    # 3.发送短信，云通讯工具包中封装好的函数功能
    ytx_send.sendTemplateSMS(mobile, [smscode, '10'], 1)
 
    # 响应
    return jsonify(result=3)
```
在mian.JS中修改如下代码：

``` javascript
// 发送短信验证码的点击事件，页面css已经由前端绑定好
function sendSMSCode() {
    // 校验参数，保证输入框有数据填写
	// 先移除绑定事件，防止用户不符合条件下点击执行函数
    $(".get_code").removeAttr("onclick");
	// 前端检验规则
    var mobile = $("#register_mobile").val();
    if (!mobile) {
        $("#register-mobile-err").html("请填写正确的手机号！");
        $("#register-mobile-err").show();
        $(".get_code").attr("onclick", "sendSMSCode();");
        return;
    }
    var imageCode = $("#imagecode").val();
    if (!imageCode) {
        $("#image-code-err").html("请填写验证码！");
        $("#image-code-err").show();
        $(".get_code").attr("onclick", "sendSMSCode();");
        return;
    }

    // TODO 发送短信验证码
	// 根据后端返回的json数据实现不同提示，局部刷新，要使用ajax请求
    $.get('/user/sms_code',{
        'mobile':mobile,
        'imagecode':imageCode,
    },function (data) {
        if(data.result==1){
            alert('请填写完整数据');
        }else if(data.result==2 || data.result==4){
            alert('图形验证码错误');
            $(".get_code").attr("onclick", "sendSMSCode();");
            generateImageCode();
            $("#imagecode").val('');
        }else if(data.result==3){
            alert('请查看手机');
        }
    });
}

```
至于短信验证码等待60秒功能会在下文Django的框架中实现。
## Django框架
前后端分离相比于Flas,k所以不需要再写前端代码，只要按照restful的开发格式，返回json数据即可

### 短信验证码
djang框架实现短信验证码功能，同样使用第三方工具包云通讯功能，云通讯配置及使用方法在上述过程中已有介绍，这里就不在赘述。

#### Django框架API接口设计
访问方式： GET /sms_codes/(?P<mobile>1[3-9]\d{9})/

请求参数： 路径参数与查询字符串参数

| 参数   | 类型 | 是否必须 | 说明 |
| ------ | ---- | -------- | ---- |
| <font color="#000000">mobile</font>  |  <font color="#000000">str</font> |  <font color="#000000">是</font>      | <font color="#000000">手机号</font>      |
返回数据：json

| 返回值  | 类型 | 是否必传 | 说明         |
| ------- | ---- | -------- | ------------ |
|  <font color="#000000">message</font> |  <font color="#000000">str</font>  | <font color="#000000">否</font>     |  <font color="#000000">OK，发送成功</font> |

#### 后端代码
在应用的urls.py中配置路由

``` javascript
urlpatterns = [
    url(r'^sms_code/(?P<mobile>1[3-9]\d{9})/$',views.SMSCodeView.as_view()),
]
```
在应用的views.py中定义视图

``` javascript
class SMSCodeView(APIView):
   
    def get(self, request, mobile):
        '''
        接收手机号，发送短信验证码
        :param mobile: 手机号
        :return: 是否成功
        '''
        # 获取redis的连接
        redis_cli = get_redis_connection('verify_code')
        # 检查是否在60s内有发送记录
        sms_flag = redis_cli.get('sms_flag_' + mobile)
        if sms_flag:
            raise serializers.ValidationError('请稍候再发送短信验证码')
        # 生成短信验证码
        sms_code = str(random.randint(100000, 999999))
        # 保存短信验证码与发送记录
        # 存验证码，300秒
        redis_cli.setex('sms_code_' + mobile, 300, sms_code)
        # 存发送标记，60秒
        redis_cli.setex('sms_flag_' + mobile, 60, 1)

        # 发送短信
        CCP.sendTemplateSMS(mobile,sms_code,5,1)
        return Response({'message': 'OK'})
```
用的djang的drf框架，别忘了导入各种包(response对象，redis数据库连接，APIview，云通讯，random，序列化器)

#### 关于与redis数据库交互的优化
上边代码

``` javascript
 		# 保存短信验证码与发送记录
        # 存验证码，300秒
        redis_cli.setex('sms_code_' + mobile, 300, sms_code)
        # 存发送标记，60秒
        redis_cli.setex('sms_flag_' + mobile, 60, 1)
```
这部分代码与redis数据库交互了两次，如何进行优化，只交互一次呢？
采用redis管道，代码如下：

``` javascript
 		# 优化redis交互，减少通信的次数，管道pipeline
        redis_pl = redis_cli.pipeline()
        redis_pl.setex('sms_code_' + mobile, 300, sms_code)
        redis_pl.setex('sms_flag_' + mobile, 60, 1)
        redis_pl.execute()
```
即可优化redis的交互次数。
