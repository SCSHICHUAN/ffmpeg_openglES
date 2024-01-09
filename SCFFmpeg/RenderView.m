//
//  RenderView.m
//  SCFFmpeg
//
//  Created by stan on 2024/1/2.
//  Copyright © 2024 石川. All rights reserved.
//

#import "RenderView.h"

uint8_t* pixels;
int height;
int width;

@interface RenderView ()

@property(nonatomic,strong)NSMutableArray *colosr;

@end

@implementation RenderView
//void printRGB24Values(uint8_t* t_pixels,int t_width,int t_height){
//    pixels = t_pixels;
//    width = t_width;
//    height = t_height;
//    for (int i = 0; i < height; i++) {
//        for (int j = 0; j < width * 3; j += 3) {
//            uint8_t red = pixels[i * (width * 3) + j];
//            uint8_t green = pixels[i * (width * 3) + j + 1];
//            uint8_t blue = pixels[i * (width * 3) + j + 2];
//            printf("R: %d, G: %d, B: %d\n", red, green, blue);
//            
//            //draw line
////            UIBezierPath *line = [UIBezierPath bezierPath];
////            [line moveToPoint:CGPointMake(i, j)];
////            [line addLineToPoint:CGPointMake(i+1,j+1)];
////            [line setLineWidth:1.0];
////            [[UIColor colorWithRed:red/255.0 green:green/255.0 blue:blue/255.0 alpha:1.00f] setStroke];
////            [line stroke];
//        }
//    }
//}

-(void)drowColor{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setNeedsDisplay];
    });
}
- (void)drawRect:(CGRect)rect {
    // Drawing code.
 
    
//    for (int i = 0; i < height; i++) {
//        for (int j = 0; j < width * 3; j += 3) {
//            uint8_t red = pixels[i * (width * 3) + j];
//            uint8_t green = pixels[i * (width * 3) + j + 1];
//            uint8_t blue = pixels[i * (width * 3) + j + 2];
//            printf("R: %d, G: %d, B: %d\n", red, green, blue);
//
//            //draw line
////            UIBezierPath *line = [UIBezierPath bezierPath];
////            [line moveToPoint:CGPointMake(i, j)];
////            [line addLineToPoint:CGPointMake(i+1,j+1)];
////            [line setLineWidth:1.0];
////            [[UIColor colorWithRed:red/255.0 green:green/255.0 blue:blue/255.0 alpha:1.00f] setStroke];
////            [line stroke];
//        }
//    }
   
    
  
}

-(NSMutableArray *)colosr{
    if(!_colosr){
        _colosr = [NSMutableArray array];
    }
    return _colosr;
}

@end
