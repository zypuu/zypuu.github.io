<div id="player1" class="aplayer"></div>
<script src="/js/src/APlayer.min.js"></script>
<script type="text/javascript">
var ap1 = new APlayer({
        element: document.getElementById('player1'),                       // Optional, player element
        narrow: false,                                                     // Optional, narrow style
        autoplay: true,                                                    // Optional, autoplay song(s), not supported by mobile browsers
        showlrc: 0,                                                        // Optional, show lrc, can be 0, 1, 2, see: ###With lrc
        mutex: true,                                                       // Optional, pause other players when this player playing
        theme: '#8B008B',                                                  // Optional, theme color, default: #b7daff
        mode: 'order',                                                    // Optional, play mode, can be `random` `single` `circulation`(loop) `order`(no loop), default: `circulation`
        preload: 'metadata',                                               // Optional, the way to load music, can be 'none' 'metadata' 'auto', default: 'auto'
        listmaxheight: '65px',                                             // Optional, max height of play list
        music: [
        {
            title: 'A Little Story',
            author: 'Valentin',
            url: 'http://music.163.com/song/media/outer/url?id=857896.mp3',
            pic: 'http://p2.so.qhimgs1.com/bdr/_240_/t01d85b3c19301a9db2.jpg'
        },
        {
            title: 'Radioactive',
            author: 'William Joseph',
            url: 'http://music.163.com/song/media/outer/url?id=27903692.mp3',
            pic: 'http://p0.so.qhimgs1.com/bdr/_240_/t01c8b1b2ea836dc744.jpg'
        },
        {
            title: 'Journey',
            author: 'Capo Productions',
            url: 'http://music.163.com/song/media/outer/url?id=16846088.mp3',
            pic: 'http://p3.so.qhmsg.com/bdr/_240_/t0139e580781f6e30b8.jpg'
        },
        {
            title: '花鳥風月',                                          // Required, music title
            author: 'コアラモード.',                          // Required, music authorhttp://music.163.com/song/media/outer/url?id=718418.mp3
            url: 'http://music.163.com/song/media/outer/url?id=550138127.mp3',  // Required, music url
            pic: 'http://p2.so.qhimgs1.com/bdr/_240_/t01cb31d8f5dd83801e.jpg'
        },
        {
            title: 'I SAY YES(wedding version)',
            author: '光宗信吉',
            url: 'http://music.163.com/song/media/outer/url?id=28191063.mp3',
            pic: 'http://p2.so.qhimgs1.com/bdr/_240_/t019619e63e4202ecbe.jpg'
        },
        {
            title: '比翼の羽根',
            author: 'eufonius',
            url: 'http://music.163.com/song/media/outer/url?id=718418.mp3',
            pic: 'http://p1.so.qhimgs1.com/bdr/_240_/t0139d306c2fe380a61.jpg'
        },
        {
            title: '远い空へ',
            author: '缘之空',
            url: 'http://music.163.com/song/media/outer/url?id=440357242.mp3',
            pic: 'http://p2.so.qhmsg.com/bdr/_240_/t01c290ef4e9134fb97.jpg'
        },
         {
            title: '夜明',
            author: '佐藤康夫',
            url: 'http://music.163.com/song/media/outer/url?id=29047169.mp3',
            pic: 'http://p1.so.qhimgs1.com/bdr/_240_/t019ae8482762b92afd.jpg'
        },
         {
            title: 'Kimi Wo Omou Melodi',
            author: 'Atchorite',
            url: 'http://music.163.com/song/media/outer/url?id=26524343.mp3',
            pic: 'http://p3.so.qhimgs1.com/bdr/_240_/t01de9733d51958de33.jpg'
        },
        {
            title: 'The Right Path',
            author: 'Thomas Greenberg',
            url: 'http://music.163.com/song/media/outer/url?id=2061452.mp3',
            pic: 'http://p2.so.qhimgs1.com/bdr/_240_/t01acf27e4a905fccae.jpg'
        }

        ]
});
</script>