//
//  sl_mpViewController.m
//  AudioStream
//
//  Created by Steven Dourmashkin on 5/28/14.
//  Copyright (c) 2014 Steven Dourmashkin. All rights reserved.
//

#import "sl_mpViewController.h"

@interface sl_mpViewController ()
@end

int r=0;
SInt16  *audiostream;
int nSamples;
int nChannels;
float minL= INFINITY;
float maxL=0;
float minR= INFINITY;
float maxR=0;
float maxBarHeight= 150;
NSMutableData *songdata;
NSMutableArray *bitsR;
NSMutableArray *bitsL;

float animateDur= 0.001;

int testint;

const int LOG_N = 4; // Typically this would be at least 10 (i.e. 1024pt FFTs)
const int N = 1 << LOG_N;


@implementation sl_mpViewController
@synthesize player, imageView, currentTimeLabel, currentTimeBar, lBar, rBar, avgBar, testBar, testLabel, backgroundView;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    bitsL= [[NSMutableArray alloc] init];
    bitsR= [[NSMutableArray alloc] init];
    
	// Do any additional setup after loading the view, typically from a nib.
    
    
    //[self importMediaItem];
    
    /*
    NSString *soundFilePath = [[NSBundle mainBundle] pathForResource:@"JaggerBomb" ofType:@"mp3"];
    //NSString *soundFilePath = @"JaggerBomb.mp3";
    NSLog(@"Audio path: %@", soundFilePath);
    
    NSError *error;
    player =[[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:soundFilePath] error:&error];
    
    if (error) {
        NSLog(@"Error in audioPlayer: %@",[error localizedDescription]);
    }
    else {
        [player setDelegate:self];
        [player setNumberOfLoops:3]; //just to make sure it is playing my file several times
        player.volume = 1.0f;
        
        if([player prepareToPlay]) //It is always ready to play
            NSLog(@"It is ready to play");
        else
            NSLog(@"It is NOT ready to play ");
        
        if([player play]) //It is always playing
            NSLog(@"It should be playing");
        else
            NSLog(@"An error happened");
    }
     */
    testint= -1;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(UIImage *) audioImageGraph:(SInt16 *) samples
                normalizeMax:(SInt16) normalizeMax
                 sampleCount:(NSInteger) sampleCount
                channelCount:(NSInteger) channelCount
                 imageHeight:(float) imageHeight {
    
    CGSize imageSize = CGSizeMake(sampleCount, imageHeight);
    UIGraphicsBeginImageContext(imageSize);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextSetAlpha(context,1.0);
    CGRect rect;
    rect.size = imageSize;
    rect.origin.x = 0;
    rect.origin.y = 0;
    
    CGColorRef leftcolor = [[UIColor whiteColor] CGColor];
    CGColorRef rightcolor = [[UIColor redColor] CGColor];
    
    CGContextFillRect(context, rect);
    
    CGContextSetLineWidth(context, 1.0);
    
    float halfGraphHeight = (imageHeight / 2) / (float) channelCount ;
    float centerLeft = halfGraphHeight;
    float centerRight = (halfGraphHeight*3) ;
    float sampleAdjustmentFactor = (imageHeight/ (float) channelCount) / (float) normalizeMax;
    
    for (NSInteger intSample = 0 ; intSample < sampleCount ; intSample ++ ) {
        SInt16 left = *samples++;
        maxL= MAX(maxL,ABS((float)left));
        [bitsL addObject:[NSNumber numberWithFloat:ABS((float)left)]];
        //minL= MIN(minL, (float)left);
        float pixels = (float) left;
        pixels *= sampleAdjustmentFactor;
        CGContextMoveToPoint(context, intSample, centerLeft-pixels);
        CGContextAddLineToPoint(context, intSample, centerLeft+pixels);
        CGContextSetStrokeColorWithColor(context, leftcolor);
        CGContextStrokePath(context);
        
        if (channelCount==2) {
            SInt16 right = *samples++;
            maxR= MAX(maxR, ABS((float)right));
            [bitsR addObject:[NSNumber numberWithFloat:ABS((float)right)]];
            float pixels = (float) right;
            pixels *= sampleAdjustmentFactor;
            CGContextMoveToPoint(context, intSample, centerRight - pixels);
            CGContextAddLineToPoint(context, intSample, centerRight + pixels);
            CGContextSetStrokeColorWithColor(context, rightcolor);
            CGContextStrokePath(context);
        }
    }
    
    // Create new image
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // Tidy up
    UIGraphicsEndImageContext();
    
    [imageView setImage:newImage];
    
    return newImage;
}

- (NSData *) renderPNGAudioPictogramForAssett:(AVURLAsset *)songAsset {
    
    NSError * error = nil;
    
    
    AVAssetReader * reader = [[AVAssetReader alloc] initWithAsset:songAsset error:&error];
    
    AVAssetTrack * songTrack = [songAsset.tracks objectAtIndex:0];
    
    NSDictionary* outputSettingsDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                                        
                                        [NSNumber numberWithInt:kAudioFormatLinearPCM],AVFormatIDKey,
                                        //     [NSNumber numberWithInt:44100.0],AVSampleRateKey, /*Not Supported*/
                                        //     [NSNumber numberWithInt: 2],AVNumberOfChannelsKey,    /*Not Supported*/
                                        
                                        [NSNumber numberWithInt:16],AVLinearPCMBitDepthKey,
                                        [NSNumber numberWithBool:NO],AVLinearPCMIsBigEndianKey,
                                        [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,
                                        [NSNumber numberWithBool:NO],AVLinearPCMIsNonInterleaved,
                                        
                                        nil];
    
    
    AVAssetReaderTrackOutput* output = [[AVAssetReaderTrackOutput alloc] initWithTrack:songTrack outputSettings:outputSettingsDict];
    
    [reader addOutput:output];
    
    //[output release];
    
    UInt32 sampleRate,channelCount;
    
    NSArray* formatDesc = songTrack.formatDescriptions;
    for(unsigned int i = 0; i < [formatDesc count]; ++i) {
        CMAudioFormatDescriptionRef item = (__bridge CMAudioFormatDescriptionRef)[formatDesc objectAtIndex:i];
        const AudioStreamBasicDescription* fmtDesc = CMAudioFormatDescriptionGetStreamBasicDescription (item);
        if(fmtDesc ) {
            
            sampleRate = fmtDesc->mSampleRate;
            channelCount = fmtDesc->mChannelsPerFrame;
            
            //    NSLog(@"channels:%u, bytes/packet: %u, sampleRate %f",fmtDesc->mChannelsPerFrame, fmtDesc->mBytesPerPacket,fmtDesc->mSampleRate);
        }
    }
    
    
    UInt32 bytesPerSample = 2 * channelCount;
    SInt16 normalizeMax = 0;
    
    NSMutableData * fullSongData = [[NSMutableData alloc] init];
    [reader startReading];
    
    
    UInt64 totalBytes = 0;
    
    
    SInt64 totalLeft = 0;
    SInt64 totalRight = 0;
    NSInteger sampleTally = 0;
    
    NSInteger samplesPerPixel = sampleRate / 50;
    
    
    while (reader.status == AVAssetReaderStatusReading){
        
        AVAssetReaderTrackOutput * trackOutput = (AVAssetReaderTrackOutput *)[reader.outputs objectAtIndex:0];
        CMSampleBufferRef sampleBufferRef = [trackOutput copyNextSampleBuffer];
        
        if (sampleBufferRef){
            CMBlockBufferRef blockBufferRef = CMSampleBufferGetDataBuffer(sampleBufferRef);
            
            size_t length = CMBlockBufferGetDataLength(blockBufferRef);
            totalBytes += length;
            
            
            //NSAutoreleasePool *wader = [[NSAutoreleasePool alloc] init];
            @autoreleasepool {
                
            
            
            NSMutableData * data = [NSMutableData dataWithLength:length];
            CMBlockBufferCopyDataBytes(blockBufferRef, 0, length, data.mutableBytes);
            
            
            SInt16 * samples = (SInt16 *) data.mutableBytes;
            int sampleCount = length / bytesPerSample;
            for (int i = 0; i < sampleCount ; i ++) {
                
                SInt16 left = *samples++;
                
                totalLeft  += left;
                
                
                
                SInt16 right;
                if (channelCount==2) {
                    right = *samples++;
                    
                    totalRight += right;
                }
                
                sampleTally++;
                
                if (sampleTally > samplesPerPixel) {
                    
                    left  = totalLeft / sampleTally;
                    
                    SInt16 fix = abs(left);
                    if (fix > normalizeMax) {
                        normalizeMax = fix;
                    }
                    
                    
                    [fullSongData appendBytes:&left length:sizeof(left)];
                    
                    if (channelCount==2) {
                        right = totalRight / sampleTally;
                        
                        
                        SInt16 fix = abs(right);
                        if (fix > normalizeMax) {
                            normalizeMax = fix;
                        }
                        
                        
                        [fullSongData appendBytes:&right length:sizeof(right)];
                    }
                    totalLeft   = 0;
                    totalRight  = 0;
                    sampleTally = 0;
                    
                }
            }
            
            
            }
            //[wader drain];
            
            
            CMSampleBufferInvalidate(sampleBufferRef);
            
            CFRelease(sampleBufferRef);
        }
    }
    
    
    NSData * finalData = nil;
    
    if (reader.status == AVAssetReaderStatusFailed || reader.status == AVAssetReaderStatusUnknown){
        // Something went wrong. return nil
        
        return nil;
    }
    
    if (reader.status == AVAssetReaderStatusCompleted){
        
        NSLog(@"rendering output graphics using normalizeMax %d",normalizeMax);
        
        UIImage *test = [self audioImageGraph:(SInt16 *) 
                         fullSongData.bytes 
                                 normalizeMax:normalizeMax 
                                  sampleCount:fullSongData.length / 4 
                                 channelCount:2
                                  imageHeight:100];
        
        finalData = UIImagePNGRepresentation(test);
        audiostream= (SInt16 *)fullSongData.bytes;
        songdata= fullSongData;
        nSamples= fullSongData.length;
        nChannels= 2;
    }
    


    /*
    
    [fullSongData release];
    [reader release];
    */
    return finalData;
}


-(void) playSong:(NSString*) song ofType: (NSString*) type{
    
    NSString *soundFilePath = [[NSBundle mainBundle] pathForResource:song ofType:type];
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:soundFilePath] options:nil];
    
    [self renderPNGAudioPictogramForAssett: asset];
    
    //NSString *soundFilePath = @"JaggerBomb.mp3";
    NSLog(@"Audio path: %@", soundFilePath);
    
    NSError *error;
    player =[[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:soundFilePath] error:&error];
    
    if (error) {
        NSLog(@"Error in audioPlayer: %@",[error localizedDescription]);
    }
    else {
        [player setDelegate:self];
        [player setNumberOfLoops:3]; //just to make sure it is playing my file several times
        player.volume = 1.0f;
        
        if([player prepareToPlay]) //It is always ready to play
            NSLog(@"It is ready to play");
        else
            NSLog(@"It is NOT ready to play ");
        
        if([player play]) //It is always playing
            NSLog(@"It should be playing");
        else
            NSLog(@"An error happened");
    }
    
    [timer invalidate];
    NSLog(@"11111");
    timer = [NSTimer scheduledTimerWithTimeInterval:.01
                                             target:self
                                           selector:@selector(updateTime:)
                                           userInfo:nil
                                            repeats:YES];
    NSLog(@"222222");
    
    
}

#define imgExt @"png"
#define imageToData(x) UIImagePNGRepresentation(x)


+ (NSString *) assetCacheFolder  {
    NSArray  *assetFolderRoot = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return [NSString stringWithFormat:@"%@/audio", [assetFolderRoot objectAtIndex:0]];
}


+ (NSString *) cachedAudioPictogramPathForMPMediaItem:(MPMediaItem*) item {
    NSString *assetFolder = [[self class] assetCacheFolder];
    NSNumber * libraryId = [item valueForProperty:MPMediaItemPropertyPersistentID];
    NSString *assetPictogramFilename = [NSString stringWithFormat:@"asset_%@.%@",libraryId,imgExt];
    return [NSString stringWithFormat:@"%@/%@", assetFolder, assetPictogramFilename];
    
}

+ (NSString *) cachedAudioFilepathForMPMediaItem:(MPMediaItem*) item {
    NSString *assetFolder = [[self class] assetCacheFolder];
    
    NSURL    * assetURL = [item valueForProperty:MPMediaItemPropertyAssetURL];
    NSNumber * libraryId = [item valueForProperty:MPMediaItemPropertyPersistentID];
    
    NSString *assettFileExt = [[[assetURL path] lastPathComponent] pathExtension];
    NSString *assetFilename = [NSString stringWithFormat:@"asset_%@.%@",libraryId,assettFileExt];
    return [NSString stringWithFormat:@"%@/%@", assetFolder, assetFilename];
}


- (NSURL *) cachedAudioURLForMPMediaItem:(MPMediaItem*) item {
    NSString *assetFilepath = [[self class] cachedAudioFilepathForMPMediaItem:item];
    return [NSURL fileURLWithPath:assetFilepath];
}

//example:
-(void) importMediaItem {
    
    //MPMediaItem* item = [self mediaItem];
    
    NSString *soundFilePath = [[NSBundle mainBundle] pathForResource:@"JaggerBomb" ofType:@"mp3"];
    
    /*
    player =[[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:soundFilePath] error:&error];
     */
   // MPMediaItem* item= [[MPMediaItem init] initFileURLWithPath:soundFilePath];
    
    // since we will be needing this for playback, save the url to the cached audio.
    
    // [url release];
    
    // url = [self cachedAudioURLForMPMediaItem:item];
    
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:soundFilePath] options:nil];

    
    //[waveFormImage release];
    //AVURLAsset *asset= [AVURLAsset URLAssetWithURL:url options:nil];
    
    [self renderPNGAudioPictogramForAssett: asset];
    
    /*
    waveFormImage = [[UIImage alloc ] initWithMPMediaItem:item completionBlock:^(UIImage* delayedImagePreparation){
        
        waveFormImage = [delayedImagePreparation retain];
        [self displayWaveFormImage];
        
    }];
    
    if (waveFormImage) {
        [waveFormImage retain];
        [self displayWaveFormImage];
    }
     */
}
//log:
#define absX(x) (x<0?0-x:x)
#define minMaxX(x,mn,mx) (x<=mn?mn:(x>=mx?mx:x))
#define noiseFloor (-90.0)
#define decibel(amplitude) (20.0 * log10(absX(amplitude)/32767.0))

- (IBAction)nextBtn:(id)sender {
    NSArray *songs = [NSArray arrayWithObjects:@"JaggerBomb",@"Lost",@"Timelines",@"Kelsey",@"Yellow",nil];
    NSArray *types= [NSArray arrayWithObjects:@"mp3",@"m4a",@"m4a",@"m4p",@"m4a", nil];
    NSString *song;
    NSString *type;
    if (r < [songs count]){
        song= [songs objectAtIndex:r];
        type= [types objectAtIndex:r];
        r++;
    }
    
    [self playSong:song ofType:type];
    
    


}

-(void)setHue:(float)h brightness:(float)b{
    //    [self setHue:0.5 brightness:0.89];
    
        backgroundView.backgroundColor = [UIColor colorWithHue:h saturation:.4 brightness:b alpha:1];

}


- (IBAction)testBtn:(id)sender {
    
    /*
    [UIView setAnimationBeginsFromCurrentState:true];

    
    testLabel.font = [UIFont boldSystemFontOfSize:45];
    testLabel.transform = CGAffineTransformScale(testLabel.transform, 0.25, 0.25);
    [self.view addSubview:testLabel];
    
    [UIView animateWithDuration:1.0 animations:^{
        testLabel.transform = CGAffineTransformScale(testLabel.transform, 4, 4);
    }];
    
    [UIView animateWithDuration:animateDur delay:0 options:(UIViewAnimationOptionBeginFromCurrentState) animations:^{
        testint=-testint;
        CGRect theFrame = testBar.frame;
        theFrame.size.height += testint * 50.f;
        testBar.frame = theFrame;
    } completion:^(BOOL finished) {
        
    }];
    
    */
    
    
    
    int numSamples = 10;  // The number of samples
    
    // Setup the length
    vDSP_Length log2n = log2f(numSamples);
    
    // Calculate the weights array. This is a one-off operation.
    FFTSetup fftSetup = vDSP_create_fftsetup(log2n, FFT_RADIX2);
    
    // For an FFT, numSamples must be a power of 2, i.e. is always even
    int nOver2 = numSamples/2;
    
    // Populate *window with the values for a hamming window function
    float *window = (float *)malloc(sizeof(float) * numSamples);
    vDSP_hamm_window(window, numSamples, 0);
    // Window the samples
    
    NSMutableArray *bitsL_new= [[NSMutableArray alloc] init];
    for (int k=0; k<numSamples; k++){
        [bitsL_new addObject: [NSNumber numberWithFloat: ([[bitsL objectAtIndex:k] floatValue]) * (window[k])]];
       // printf("at k: %f",[[bitsL_new objectAtIndex:k] floatValue]);
    }
    
    
    
    //vDSP_vmul(bitsL, 1, window, 1, samples, 1, numSamples);
    
    // Define complex buffer
    COMPLEX_SPLIT A;
    A.realp = (float *) malloc(nOver2*sizeof(float));
    A.imagp = (float *) malloc(nOver2*sizeof(float));
    
    // Pack samples:
    // C(re) -> A[n], C(im) -> A[n+1]
    float *arr = (float *) malloc(sizeof(float) * numSamples);
    for(int i=0;i<numSamples;i++)
    {
        arr[i]= [[bitsL_new objectAtIndex:i] floatValue];
    }
    vDSP_ctoz((COMPLEX*)arr, 2, &A, 1, numSamples/2);
    
    
    //Perform a forward FFT using fftSetup and A
    //Results are returned in A
    vDSP_fft_zrip(fftSetup, &A, 1, log2n, FFT_FORWARD);
    
    //Convert COMPLEX_SPLIT A result to magnitudes
    float amp[numSamples];
    amp[0] = A.realp[0]/(numSamples*2);
    printf("[");
    for(int i=1; i<numSamples; i++) {
        amp[i]=A.realp[i]*A.realp[i]+A.imagp[i]*A.imagp[i];
        printf("%f,",amp[i]);
    }
    printf("]");
    
    
}


- (void)updateTime:(NSTimer *)timer {
    //to don't update every second. When scrubber is mouseDown the the slider will not set
    currentTimeLabel.text = [NSString stringWithFormat:@"%f",
                             [player currentTime]];
    float startX=10;
    float endX=310;
    float timeRatio=([player currentTime]/[player duration]);
    if (timeRatio < 0)
        timeRatio=0;
    int nLeft= bitsL.count;
    int nRight= bitsR.count;
    
    
    float newX= timeRatio*(endX-startX) + startX;
    
    
    //adjust current time bar
    CGRect frame= currentTimeBar.frame;
    frame.origin.x= newX;
    currentTimeBar.frame= frame;
    
    //adjust sound bars...
    int sampleIdx= floor(timeRatio*nLeft);
    
    /*
    NSLog([NSString stringWithFormat:@"samp: %d",sampleIdx]);
    NSLog([NSString stringWithFormat:@"time: %f",timeRatio]);
    NSLog([NSString stringWithFormat:@"nleft: %d",nLeft]);
     */

    //Start on left...
    /*
    if (nChannels==2 && remainder(sampleIdx, 2)==1){
        sampleIdx--;
    }
     */
    
    /*
    SInt16 bit1 = (SInt16) ([songdata subdataWithRange:NSMakeRange(sampleIdx, sampleIdx+1)]).bytes;
    SInt16 *samples= (SInt16 *) songdata.bytes;
    SInt16 bitT0 = *samples++;
    SInt16 bitT01= *samples++;
    NSData *sub=[songdata subdataWithRange:NSMakeRange(0, 1)];
    SInt16* bitT1 = (SInt16*) sub.bytes;
    NSData *sub2=[songdata subdataWithRange:NSMakeRange(1, 2)];
    SInt16* bitT2 = (SInt16*) sub2.bytes;
    NSData *sub3=[songdata subdataWithRange:NSMakeRange(2, 3)];
    SInt16* bitT3 = (SInt16*) sub3.bytes;
    NSLog([NSString stringWithFormat:@"%f",(float)*bitT3]);
*/
    
    float bit1= [[bitsL objectAtIndex:sampleIdx] floatValue];
    

      /*
       
       
    NSData *sub1=[songdata subdataWithRange:NSMakeRange(sampleIdx, sampleIdx+1)];
    SInt16* bit1 = (SInt16*) sub1.bytes;
    

    NSLog([NSString stringWithFormat:@"BIT1: %f",(float)*bit1]);
    NSLog([NSString stringWithFormat:@"MAX: %f",maxL]);
    
    SInt16 *samples= (SInt16 *) songdata.bytes;
    SInt16 bitT0 = *samples++;
    NSLog([NSString stringWithFormat:@"sample at 0: %hd",bitT0]);

*/

    [UIView animateWithDuration:animateDur delay:0 options:(UIViewAnimationOptionBeginFromCurrentState) animations:^{

    CGRect lFrame= lBar.frame;
    
    float lRatio= bit1/maxL;
    lFrame.size.height= maxBarHeight * lRatio;
    //NSLog([NSString stringWithFormat:@"BIT1: %f",bit1]);
   //NSLog([NSString stringWithFormat:@"RAT: %f",lRatio]);
    lBar.frame= lFrame;
        
    } completion:^(BOOL finished) {
        
    }];
    
    if (nChannels==2){
       // sampleIdx++;
        /*
        NSData *sub2=[songdata subdataWithRange:NSMakeRange(sampleIdx, sampleIdx+1)];
        SInt16* bit2 = (SInt16*) sub2.bytes;
         */
        float bit2= [[bitsR objectAtIndex:sampleIdx] floatValue];

        [UIView animateWithDuration:animateDur delay:0 options:(UIViewAnimationOptionBeginFromCurrentState) animations:^{

            
        CGRect rFrame= rBar.frame;
        rFrame.size.height= maxBarHeight * ((float)bit2)/maxR;
        rBar.frame= rFrame;
            
        } completion:^(BOOL finished) {
            
        }];
        
        float avgBit= ((float)bit1 + (float)bit2) / 2;
        [UIView animateWithDuration:animateDur delay:0 options:(UIViewAnimationOptionBeginFromCurrentState) animations:^{

        CGRect avgFrame= avgBar.frame;
        avgFrame.size.height= maxBarHeight * 2*avgBit/(maxR+maxL);
        avgBar.frame= avgFrame;
        } completion:^(BOOL finished) {
            
        }];
    }
    
    
    
    
}

@end