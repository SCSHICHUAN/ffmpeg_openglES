//
//  RenderView.h
//  SCFFmpeg
//
//  Created by stan on 2024/1/2.
//  Copyright © 2024 石川. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface RenderView : UIView

void printRGB24Values(uint8_t* t_pixels,int t_width,int t_height);
-(void)drowColor;


@end

NS_ASSUME_NONNULL_END
