<%--
  Created by IntelliJ IDEA.
  User: ff
  Date: 16-4-16
  Time: 上午10:52
  To change this template use File | Settings | File Templates.
--%>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
  String path = request.getContextPath();
  String basePath = request.getScheme()+"://"+request.getServerName()+":"+request.getServerPort()+path+"/";
%>
<html>
<head>
  <base href="<%=basePath%>">
  <title>My JSP 'index.jsp' starting page</title>
  <script type="text/javascript">

    var address=window.location.href;
    var sll = address.split("/");
    var ip = sll[2];
    console.log("服务器ｉｐ"+ip);

    var socket =new WebSocket("ws://"+ip+"/msp");
    var tstream ={
      //audio:true,
      video:{mandatory: {maxWidth: 352,maxHeight: 320,maxFrameRate: 10}}
    };
    var  locatstream =null;
    var servers ={iceServers:[]};

    socket.onopen = function(evt){
      console.log("open");
    };
    socket.onclose=function(evt){
      console.log(evt);
    };
    //浏览器兼容  获取摄像头
    navigator.getUserMedia=(navigator.getUserMedia ||
    navigator.webkitGetUserMedia ||
    navigator.mozGetUserMedia ||
    navigator.msGetUserMedia);
    //建立流通道的兼容方法
    var PeerConnection =(window.webkitRTCPeerConnection || window.mozRTCPeerConnection || window.RTCPeerConnection || undefined);
    var RTCSessionDescription = (window.webkitRTCSessionDescription || window.mozRTCSessionDescription || window.RTCSessionDescription || undefined);
    var pc ;
    //将流绑定到Video上
    navigator.getUserMedia(tstream,getUserStream,function error(error){console.log(error);});
    function getUserStream(stream){
      //将流绑定到video上
      document.getElementById("vid1").src=window.URL.createObjectURL(stream);
      locatstream =stream;

    };

    //发送连接消息

    function con(){
      pc = new PeerConnection(servers);
      console.log("已将流装载");
      pc.addStream(locatstream);
      pc.onaddstream=function(e){
        console.log(e.stream);
        document.getElementById("vid2").src=window.URL.createObjectURL(e.stream);
        console.log("获取远程媒体成功");
      }
      pc.onicecandidate =function(event){
        socket.send(JSON.stringify({
          'type':"icecandidate",
          'state':"con",
          'data':{'candidate':event.candidate}}));
      };
      console.log("发送icecandidate");

      pc.createOffer(function(offer){
        pc.setLocalDescription(offer);
        var obj =JSON.stringify({
          'type':"offer",
          'state':"con",
          'data':offer
        });
        socket.send(obj);
        console.log("发送offer");
      });

    };
    socket.onmessage= function(Message){
      var obj = JSON.parse(Message.data);
      var type =obj.type;
      switch(type){
        case "offer":
          console.log("1获得offer");
          pc = new PeerConnection(servers);
          var rtcs =new  RTCSessionDescription(obj.data);
          pc.setRemoteDescription(rtcs);
          pc.onicecandidate =function(event){
            socket.send(JSON.stringify({
              'type':"icecandidate",
              'state':"con",
              'data':{'candidate':event.candidate}}));
          };
          console.log("1已将流装载");
          pc.addStream(locatstream);
          pc.onaddstream=function(e){
            console.log(e.stream);
            document.getElementById("vid2").src=window.URL.createObjectURL(e.stream);
            console.log("1获取远程媒体成功");
          }
          pc.createAnswer(function(desc){
            console.log(desc);
            console.log("1发送answer");
            pc.setLocalDescription(desc);
            socket.send(JSON.stringify({
              'type':"answer",
              'state':"con",
              'data':desc
            }));
            console.log("aa");
          });

          break;
        case "answer":
          var rtcs =new RTCSessionDescription(obj.data);
          console.log("1获得answer");
          pc.setRemoteDescription(rtcs);
          break;
        case"icecandidate":
          console.log("1获得icecandidate");
          console.log(obj.data.candidate);
          pc.addIceCandidate(new RTCIceCandidate(obj.data.candidate));
          break;
        default:
          console.log(Message.data);

      }
    }

    function send(){
      socket.send("hello");
    }

  </script>
</head>

<body>
<div>
  <video id="vid1" width="640" height="480" autoplay></video>
  <video id="vid2" width="640" height="480" autoplay></video>
</div>
<div algin="center">
  <input type ="button" value="开始" onclick="con()"/>
  <input type ="button" value="发送" onclick="send()"/>
</div>
</body>
</html>