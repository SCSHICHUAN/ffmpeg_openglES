//
//  ViewController.m
//  SCFFmpeg
//
//  Created by 石川 on 2019/5/18.
//  Copyright © 2019 石川. All rights reserved.
//

#import "ViewController.h"
#include "libavutil/log.h"
#include "libavformat/avio.h"
#include "libavformat/avformat.h"
#include "libavcodec/avcodec.h"
#include "libswscale/swscale.h"
#include <AVKit/AVKit.h>
#import "RenderView.h"
#import <OpenGLES/ES3/glext.h>
#import <GLKit/GLKit.h>
#define kWidth ([UIScreen mainScreen].bounds.size.width)

ViewController *c_self;

@interface ViewController ()  {
    GLKView *glView;
}
@property(nonatomic,assign)BOOL end;
@property(nonatomic,strong)UILabel *lab;
@property(nonatomic,assign)NSInteger video_pak_count;
@property(nonatomic,assign)NSInteger audio_pak_count;
@property(nonatomic,strong)RenderView *renderView;

@end

@implementation ViewController

-(void)testClick{
    self.end = YES;
}
-(void)open{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.lab.text = @"写入音频平数据中....";
        NSString *document = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
        NSLog(@"document=%@",document);
    });
}
-(void)open2{
    dispatch_async(dispatch_get_main_queue(), ^{
        AVPlayerViewController *pvc = [[AVPlayerViewController alloc] init];
        NSString *document = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
        NSString *path = [document stringByAppendingPathComponent:@"sc.mp4"];
        NSURL *url = [[NSURL alloc] initFileURLWithPath:path];
        pvc.player = [[AVPlayer alloc] initWithURL:url];
        [pvc.player play];
        [self presentViewController:pvc animated:YES completion:nil];
    });
}

-(void)testClick2{
    self.end = NO;
    self.video_pak_count = 0;
    self.audio_pak_count = 0;
    self.lab.text = @"拉流中请稍等...";
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self run];
    });
    
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    {
        UIButton *test = [UIButton buttonWithType:UIButtonTypeCustom];
        [[UIApplication sharedApplication].keyWindow addSubview:test];
        test.frame = CGRectMake(50, 100, kWidth-100, 40);;
        test.backgroundColor = UIColor.blueColor;
        [test setTitle:@"START 开始拉流" forState:UIControlStateNormal];
        [test addTarget:self action:@selector(testClick2) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:test];
    }
    UIButton *test = [UIButton buttonWithType:UIButtonTypeCustom];
    [[UIApplication sharedApplication].keyWindow addSubview:test];
    test.frame = CGRectMake(50, 180, kWidth-100, 40);
    test.backgroundColor = UIColor.redColor;
    [test setTitle:@"STOP 停止拉流" forState:UIControlStateNormal];
    [test addTarget:self action:@selector(testClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:test];
    
    UILabel *lab = [[UILabel alloc] initWithFrame: CGRectMake(50, 250, kWidth-100, 40)];
    lab.backgroundColor = UIColor.blackColor;
    lab.textColor = UIColor.whiteColor;
    [self.view addSubview:lab];
    self.lab = lab;
    view = self.view;
    arry = [NSMutableArray array];
    count = 0;
    c_self = self;
    _display_rgb_queue =   dispatch_queue_create("display rgb queue",
                                                 DISPATCH_QUEUE_SERIAL);
    [self _creatOpenGLContent];
    [self _setupOpenGLProgram];
    [self _setupOpenGL];
}




dispatch_queue_t _display_rgb_queue;
/// 顶点对象
GLuint _VBO;
GLuint _VAO;
GLuint _yTexture;
GLuint _uTexture;
GLuint _vTexture;
GLuint _glProgram;
/// 顶点着色器
GLuint _vertextShader;
/// 片段着色器
GLuint _fragmentShader;

-(void)_creatOpenGLContent{
    glView = [[GLKView alloc] initWithFrame:CGRectMake(0, 300, kWidth, kWidth*(9/16.0))];
    glView.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    [EAGLContext setCurrentContext:glView.context];
    [self.view addSubview:glView];
}


#pragma mark - OpenGL
/// 编译着色器
- (GLuint)_compileShader:(NSString *)shaderName shaderType:(GLuint)shaderType {
    if(shaderName.length == 0) return -1;
    NSString *shaderPath = [[NSBundle mainBundle] pathForResource:shaderName ofType:@"glsl"];
    NSError *error;
    NSString *source = [NSString stringWithContentsOfFile:shaderPath encoding:NSUTF8StringEncoding error:&error];
    if(error) return -1;
    GLuint shader = glCreateShader(shaderType);
    const char *ss = [source UTF8String];
    glShaderSource(shader, 1, &ss, NULL);
    glCompileShader(shader);
    int  success;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
    if(!success) {
        char infoLog[512];
        glGetShaderInfoLog(shader, 512, NULL, infoLog);
        printf("shader error msg: %s \n", infoLog);
    }
    return shader;
}
/// 初始化OpenGL可编程程序
- (BOOL)_setupOpenGLProgram {
//    [self.openGLContext makeCurrentContext];
    [EAGLContext setCurrentContext:glView.context];
    _glProgram = glCreateProgram();
    _vertextShader = [self _compileShader:@"vertex" shaderType:GL_VERTEX_SHADER];
    _fragmentShader = [self _compileShader:@"yuv_fragment" shaderType:GL_FRAGMENT_SHADER];
    glAttachShader(_glProgram, _vertextShader);
    glAttachShader(_glProgram, _fragmentShader);
    glLinkProgram(_glProgram);
    GLint success;
    glGetProgramiv(_glProgram, GL_LINK_STATUS, &success);
    if(!success) {
        char infoLog[512];
        glGetProgramInfoLog(_glProgram, 512, NULL, infoLog);
        printf("Link shader error: %s \n", infoLog);
    }
    glDeleteShader(_vertextShader);
    glDeleteShader(_fragmentShader);
    NSLog(@"===着色器加载成功===");
    return success;
}
- (void)_setupOpenGL {
//    [self.openGLContext makeCurrentContext];
    [EAGLContext setCurrentContext:glView.context];
    glGenVertexArrays(1, &_VAO);
    /// 创建顶点缓存对象
    glGenBuffers(1, &_VBO);
    /// 顶点数据
    float vertices[] = {
        // positions        // texture coords
        1.0f,  1.0f, 0.0f,  1.0f, 0, // top right
        1.0f, -1.0f, 0.0f,  1.0f, 1, // bottom right
       -1.0f, -1.0f, 0.0f,  0.0f, 1, // bottom left
       -1.0f, -1.0f, 0.0f,  0.0f, 1, // bottom left
       -1.0f,  1.0f, 0.0f,  0.0f, 0, // top left
        1.0f,  1.0f, 0.0f,  1.0f, 0, // top right
    };
    glBindVertexArray(_VAO);
    /// 绑定顶点缓存对象到当前的顶点位置,之后对GL_ARRAY_BUFFER的操作即是对_VBO的操作
    /// 同时也指定了_VBO的对象类型是一个顶点数据对象
    glBindBuffer(GL_ARRAY_BUFFER, _VBO);
    /// 将CPU数据发送到GPU,数据类型GL_ARRAY_BUFFER
    /// GL_STATIC_DRAW 表示数据不会被修改,将其放置在GPU显存的更合适的位置,增加其读取速度
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    
    /// 指定顶点着色器位置为0的参数的数据读取方式与数据类型
    /// 第一个参数: 参数位置
    /// 第二个参数: 一次读取数据
    /// 第三个参数: 数据类型
    /// 第四个参数: 是否归一化数据
    /// 第五个参数: 间隔多少个数据读取下一次数据
    /// 第六个参数: 指定读取第一个数据在顶点数据中的偏移量
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void*)0);
    /// 启用顶点着色器中位置为0的参数
    glEnableVertexAttribArray(0);
    
    // texture coord attribute
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void*)(3 * sizeof(float)));
    glEnableVertexAttribArray(1);
    
    glGenTextures(1, &_yTexture);
    [self _configTexture:_yTexture];
    
    glGenTextures(1, &_uTexture);
    [self _configTexture:_uTexture];
    
    glGenTextures(1, &_vTexture);
    [self _configTexture:_vTexture];
    
    glBindVertexArray(0);
    
}
- (void)_configTexture:(GLuint)texture {
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glGenerateMipmap(GL_TEXTURE_2D);
    glBindTexture(GL_TEXTURE_2D, 0);
}
#pragma mark - Override
- (void)displayWithFrame:(AVFrame *)yuvFrame {

    
    int videoWidth = yuvFrame->width;
    int videoHeight = yuvFrame->height;
//    CGLLockContext([self.openGLContext CGLContextObj]);
//    [self.openGLContext makeCurrentContext];
//    [EAGLContext setCurrentContext:glView.context];
    glClearColor(0.0, 0.0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT);
    glEnable(GL_TEXTURE_2D);
    glUseProgram(_glProgram);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _yTexture);
//    glTexImage2D(GL_TEXTURE_2D, 0, GL_RED, videoWidth, videoHeight, 0, GL_RED, GL_UNSIGNED_BYTE, yuvFrame->data[0]);
    glTexImage2D(GL_TEXTURE_2D,0,GL_LUMINANCE,videoWidth,videoHeight,0,GL_LUMINANCE,GL_UNSIGNED_BYTE,yuvFrame->data[0]);
    glUniform1i(glGetUniformLocation(_glProgram, "yTexture"), 0);
    
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, _uTexture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, videoWidth / 2, videoHeight / 2, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, yuvFrame->data[1]);
    glUniform1i(glGetUniformLocation(_glProgram, "uTexture"), 1);

    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, _vTexture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, videoWidth / 2, videoHeight / 2, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, yuvFrame->data[2]);
    glUniform1i(glGetUniformLocation(_glProgram, "vTexture"), 2);
    
    glBindVertexArray(_VAO);
    glDrawArrays(GL_TRIANGLES, 0, 6);
//    [self.openGLContext flushBuffer];
//
//    CGLUnlockContext([self.openGLContext CGLContextObj]);
    
//    glClearColor(0.3, 0.4, 0.5, 1.0);
//    glClear(GL_COLOR_BUFFER_BIT);
    [glView.context presentRenderbuffer:GL_RENDERBUFFER];

}



#define INBUF_SIZE 4096

#define WORD uint16_t
#define DWORD uint32_t
#define LONG int32_t

int wellDone;
#pragma pack(2)
UIView *view;
NSMutableArray *arry;
int count;
int stride = 2;
int stride_big = 0;
bool onec = YES;



static int decode_write_frame(const char *outfilename, AVCodecContext *avctx,
                              struct SwsContext *sws_convert_ctx, AVFrame *frame, int *frame_count, AVPacket *pkt, int last,AVStream *st,int start_time,int end_time)
{
    AVPicture *bmp;
    int len, got_frame;
    char buf[1024];
    
    /*
     开始解码
     avctx     : 编解码器环境
     frame     : 输出帧
     got_frame : 是否解码完成一帧
     pkt       : 输入数据
     */
    len = avcodec_decode_video2(avctx, frame, &got_frame, pkt);
    if (len < 0) {
        fprintf(stderr, "Error while decoding frame %d\n", *frame_count);
        return len;
    }
    //如果解码完成一帧
    if (got_frame) {
        //判断是否大于结束时间 ms
        float pkg_time = av_q2d(st->time_base) * pkt->pts * 1000;
        printf("av_pkg_time = %f ms\n",pkg_time);
        
        
        /*
         start_time < pkg_time
         修复100ms到100ms 取多帧bug
         */
        if (start_time <= pkg_time) {
            
            printf("Saving %sframe %3d\n", last ? "last " : "", *frame_count);
            count = *frame_count;
            fflush(stdout);
            
            /* the picture is allocated by the decoder, no need to free it */
            snprintf(buf, sizeof(buf), "%s-%d.bmp", outfilename, *frame_count);
            
           
            dispatch_async(dispatch_get_main_queue(), ^{
                [c_self displayWithFrame:frame];
            });
            (*frame_count)++;
        }
    }
    return 0;
}

-(int)run{
    
    
//        const char *a = "http://www.w3school.com.cn/i/movie.mp4";
    const char *a = "http://devimages.apple.com/iphone/samples/bipbop/gear1/prog_index.m3u8";
//        const char *a = "http://vjs.zencdn.net/v/oceans.mp4";
//    const char *a = "rtmp://mobliestream.c3tv.com:554/live/goodtv.sdp";


    
    
    const char *b = "/Users/stan/Desktop/p/a";
    
    const  char *argv[] ={"",a,b,"0","10000"};
    
    
    int ret;
    
    FILE *f = NULL;
    
    const char *filename, *outfilename;
    int64_t  start_time,end_time;
    
    AVFormatContext *fmt_ctx = NULL;
    
    const AVCodec *codec;
    AVCodecContext *codec_ctx= NULL;
    
    AVStream *st = NULL;
    int stream_index;
    
    int frame_count;
    AVFrame *frame;
    
    struct SwsContext *sws_convert_ctx;
    
    //uint8_t inbuf[INBUF_SIZE + AV_INPUT_BUFFER_PADDING_SIZE];
    AVPacket avpkt;
    
    
    filename    = argv[1];
    outfilename = argv[2];
    start_time  = atoi(argv[3]);
    end_time    = atoi(argv[4]);
    
    /* register all formats and codecs */
    avcodec_register_all();
    av_register_all();
    avformat_network_init();
    
    /*打开输入文件
     open input file, and allocate format context */
    if (avformat_open_input(&fmt_ctx, filename, NULL, NULL) < 0) {
        fprintf(stderr, "Could not open source file %s\n", filename);
        exit(1);
    }
    
    /*找到输入文件的信息
     retrieve stream information */
    if (avformat_find_stream_info(fmt_ctx, NULL) < 0) {
        fprintf(stderr, "Could not find stream information\n");
        exit(1);
    }
    
    /*打印输入文件的信息
     dump input information to stderr */
    av_dump_format(fmt_ctx, 0, filename, 0);
    
    
    //找到视频流
    ret = av_find_best_stream(fmt_ctx, AVMEDIA_TYPE_VIDEO, -1, -1, NULL, 0);
    if (ret < 0) {
        fprintf(stderr, "Could not find %s stream in input file '%s'\n",
                av_get_media_type_string(AVMEDIA_TYPE_VIDEO), filename);
        return ret;
    }
    
    stream_index = ret;
    //拿到视频流的实例
    st = fmt_ctx->streams[stream_index];
    
    /*
     找到视频流的编解码器
     find decoder for the stream */
    codec = avcodec_find_decoder(st->codecpar->codec_id);
    if (!codec) {
        fprintf(stderr, "Failed to find %s codec\n",
                av_get_media_type_string(AVMEDIA_TYPE_VIDEO));
        return AVERROR(EINVAL);
    }
    
    //分配编解码器上下文
    codec_ctx = avcodec_alloc_context3(NULL);
    if (!codec_ctx) {
        fprintf(stderr, "Could not allocate video codec context\n");
        exit(1);
    }
    
    /*编解码器拷贝到创建的上下文中
     Copy codec parameters from input stream to output codec context */
    if ((ret = avcodec_parameters_to_context(codec_ctx, st->codecpar)) < 0) {
        fprintf(stderr, "Failed to copy %s codec parameters to decoder context\n",
                av_get_media_type_string(AVMEDIA_TYPE_VIDEO));
        return ret;
    }
    
    
    /*打开编解码器环境
     open it */
    if (avcodec_open2(codec_ctx, codec, NULL) < 0) {
        fprintf(stderr, "Could not open codec\n");
        exit(1);
    }
    
    //图片视频裁剪 初始化
    sws_convert_ctx = sws_getContext(codec_ctx->width, codec_ctx->height,
                                     codec_ctx->pix_fmt,
                                     codec_ctx->width, codec_ctx->height,
                                     AV_PIX_FMT_BGR24,
                                     SWS_BICUBIC, NULL, NULL, NULL);
    
    if (sws_convert_ctx == NULL)
    {
        fprintf(stderr, "Cannot initialize the conversion context\n");
        exit(1);
    }
    
    //初始化frame
    frame = av_frame_alloc();
    if (!frame) {
        fprintf(stderr, "Could not allocate video frame\n");
        exit(1);
    }
    
    //初始化AVPacket
    av_init_packet(&avpkt);
    
    
    //读取输入上下文的数据
    wellDone = 0;
    frame_count = 1;
    
    
    //    while (av_read_frame(fmt_ctx, &avpkt) >= 0) {
    //        if (wellDone) {
    //            break;
    //        }
    //        //如果是视频流
    //        if(avpkt.stream_index == stream_index){
    //            if (decode_write_frame(outfilename, codec_ctx, sws_convert_ctx, frame, &frame_count, &avpkt, 0,st,start_time,end_time) < 0)
    //                exit(1);
    //        }
    //        av_packet_unref(&avpkt);
    //    }
    
    //    avpkt.data = NULL;
    //    avpkt.size = 0;
    fclose(f);
    //    avformat_close_input(&fmt_ctx);
    //    sws_freeContext(sws_convert_ctx);
    //    avcodec_free_context(&codec_ctx);
    //    av_frame_free(&frame);
    //    printf("start_time = %lld,end_time = %lld\n",start_time,end_time);
    
    [c_self redFream:fmt_ctx pkt:avpkt videoIndex:stream_index outfilename:outfilename codec_ctx:codec_ctx sws_convert_ctx:sws_convert_ctx frame:frame frame_count:frame_count st:st start_time:start_time end_time:end_time];
    
    return 0;
}


-(void)redFream:(AVFormatContext *)fmt_ctx
            pkt:(AVPacket )avpkt
     videoIndex:(int)stream_index
    outfilename:(const char*)outfilename
      codec_ctx:(AVCodecContext *)codec_ctx
sws_convert_ctx:(struct SwsContext *)sws_convert_ctx
          frame:(AVFrame *)frame
    frame_count:(int *)frame_count
             st:(AVStream *)st
     start_time:(int64_t)start_time
       end_time:(int64_t)end_time{
    
    if (av_read_frame(fmt_ctx, &avpkt) >= 0) {
        
        //如果是视频流
        if(avpkt.stream_index == stream_index){
            if (decode_write_frame(outfilename, codec_ctx, sws_convert_ctx, frame, &frame_count, &avpkt, 0,st,start_time,end_time) < 0)
                exit(1);
        }
        av_packet_unref(&avpkt);
    }
    
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((1/60.0) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [c_self redFream:fmt_ctx pkt:avpkt videoIndex:stream_index outfilename:outfilename codec_ctx:codec_ctx sws_convert_ctx:sws_convert_ctx frame:frame frame_count:frame_count st:st start_time:start_time end_time:end_time];
    });
    
    
    //    avpkt.data = NULL;
    //    avpkt.size = 0;
    ////    fclose(f);
    //    avformat_close_input(&fmt_ctx);
    //    sws_freeContext(sws_convert_ctx);
    //    avcodec_free_context(&codec_ctx);
    //    av_frame_free(&frame);
    //    printf("start_time = %lld,end_time = %lld\n",start_time,end_time);
}


@end
