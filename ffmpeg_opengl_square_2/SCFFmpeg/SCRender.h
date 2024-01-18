//
//  SCRender.h
//  SCFFmpeg
//
//  Created by stan on 2024/1/17.
//  Copyright © 2024 石川. All rights reserved.
//

#import <UIKit/UIKit.h>
#include "libavformat/avformat.h"
NS_ASSUME_NONNULL_BEGIN

@interface SCRender : UIView


- (void)displayWithFrame:(AVFrame *)yuvFrame;
@property(nonatomic,assign)float forward;
@property(nonatomic,assign)float back;
@property(nonatomic,assign)float right;
@property(nonatomic,assign)float left;
@property(nonatomic,assign)float right_R;

@end

NS_ASSUME_NONNULL_END
