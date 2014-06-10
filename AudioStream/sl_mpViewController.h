//
//  sl_mpViewController.h
//  AudioStream
//
//  Created by Steven Dourmashkin on 5/28/14.
//  Copyright (c) 2014 Steven Dourmashkin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import <Accelerate/Accelerate.h>

@interface sl_mpViewController : UIViewController{
    MPMediaItem* mediaItem;
    UIImage* waveFormImage;
    NSURL* url;
    NSTimer *timer;
}
@property (strong, nonatomic) AVAudioPlayer *player;
@property (weak, nonatomic) IBOutlet UILabel *currentTimeLabel;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIView *currentTimeBar;
@property (weak, nonatomic) IBOutlet UIView *lBar;
@property (weak, nonatomic) IBOutlet UIView *rBar;
@property (weak, nonatomic) IBOutlet UIView *avgBar;
@property (weak, nonatomic) IBOutlet UIView *testBar;
@property (weak, nonatomic) IBOutlet UILabel *testLabel;
@property (strong, nonatomic) IBOutlet UIView *backgroundView;
-(void)initWithContentsOfFile;
- (IBAction)nextBtn:(id)sender;
- (IBAction)testBtn:(id)sender;


@end
