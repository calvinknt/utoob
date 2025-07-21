#import "VideoViewController.h"

@interface VideoViewController () <NSURLConnectionDelegate>
//@property (nonatomic, strong) NSURLConnection *videoExtractConnection;
@property (nonatomic, strong) NSURLConnection *metadataConnection;
//@property (nonatomic, strong) NSMutableData *responseData;
@property (nonatomic, strong) NSMutableData *metadataResponseData;
@end

@implementation VideoViewController

- (instancetype)initWithVideo:(Video *)video {
    NSString *nibName = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    ? @"VideoViewController_iPad"
    : @"VideoViewController";
    
    self = [super initWithNibName:nibName bundle:nil];
    if (self) {
        _video = video;
        _responseData = [NSMutableData data];
        _metadataResponseData = [NSMutableData data];
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Configure audio session for playback
    NSError *audioError = nil;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:&audioError];
    if (audioError) {
        NSLog(@"Audio session error: %@", audioError);
    }
    
    [audioSession setActive:YES error:&audioError];
    if (audioError) {
        NSLog(@"Audio session activation error: %@", audioError);
    }
    
    // Start loading metadata first
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [self fetchVideoMetadata];
}

- (void)fetchVideoMetadata {
    NSLog(@"Fetching metadata for Video ID: %@", self.video.videoId);
    NSString *apiUrlString = [NSString stringWithFormat:@"%@/get-ytvideo-info.php?video_id=%@&apikey=%@", [[NSUserDefaults standardUserDefaults] stringForKey:@"url"], self.video.videoId, [[NSUserDefaults standardUserDefaults] stringForKey:@"api"]];
    NSURL *apiUrl = [NSURL URLWithString:apiUrlString];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:apiUrl];
    self.metadataConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [self.metadataResponseData setLength:0];
}

- (void)extractVideoURL {
    /*NSLog(@"Extracting video URL for Video ID: %@", self.video.videoId);
     // dont abuse my url pls, thanks
    NSString *extractUrlString = [NSString stringWithFormat:@"https://calvink19.co/services/yt/extract.php?id=%@", self.video.videoId];
    NSURL *extractUrl = [NSURL URLWithString:extractUrlString];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:extractUrl];
    self.videoExtractConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [self.responseData setLength:0];*/
    //[elf connection]
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    if (connection == self.metadataConnection) {
        [self.metadataResponseData setLength:0];
    } else {
        [self.responseData setLength:0];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    if (connection == self.metadataConnection) {
        [self.metadataResponseData appendData:data];
    } else {
        [self.responseData appendData:data];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    if (connection == self.metadataConnection) {
        // Handle metadata response
        NSError *error;
        NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:self.metadataResponseData
                                                                     options:0
                                                                       error:&error];
        
        if (error) {
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            [self showErrorAlert:@"Failed to parse video metadata"];
            return;
        }
        
        // Update video object with metadata
        self.video.title = jsonResponse[@"title"];
        self.video.author = jsonResponse[@"author"];
        self.video.views = jsonResponse[@"views"];
        self.video.likes = jsonResponse[@"likes"];
        self.video.publishedAt = jsonResponse[@"published_at"];
        self.video.duration = jsonResponse[@"duration"];
        self.video.descriptionText = jsonResponse[@"description"];
        
        // Setup UI with the new metadata
        [self setupMetadata];
        
        // Handle video URL response
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
        // Play the direct URL we received from calvink19.co
        //[self playVideoWithURL:[NSURL URLWithString:jsonResponse[@"url"]]];
        NSLog(@"URL: %@", [NSString stringWithFormat:@"%@/direct_url?video_id=%@&proxy=%@", [[NSUserDefaults standardUserDefaults] stringForKey:@"url"], self.video.videoId, [[NSUserDefaults standardUserDefaults] stringForKey:@"proxy"]]);
        [self playVideoWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/direct_url?video_id=%@&proxy=%@", [[NSUserDefaults standardUserDefaults] stringForKey:@"url"], self.video.videoId, [[NSUserDefaults standardUserDefaults] stringForKey:@"proxy"]]]];

    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    if (connection == self.metadataConnection) {
        [self showErrorAlert:@"Failed to fetch video metadata"];
    } else {
        [self showErrorAlert:@"Failed to get video URL"];
    }
    
    NSLog(@"Connection error: %@", error);
}

- (void)setupMetadata {
    if (self.navbar && self.video.title) {
        [self.navbar.topItem setTitle:self.video.title];
    }
    
    self.authorLabel.text = self.video.author ?: @"Unknown Author";
    self.viewsLabel.text = [NSString stringWithFormat:@"%@ views", self.video.views ?: @"0"];
    self.likesLabel.text = [NSString stringWithFormat:@"%@ likes", self.video.likes ?: @"0"];
    self.dateLabel.text = [self formattedDate:self.video.publishedAt] ?: @"Date not available";
    self.durationLabel.text = [self formattedDuration:self.video.duration] ?: @"";
    self.descriptionView.text = self.video.descriptionText ?: @"No description available";
    
    // Debug output
    NSLog(@"Video ID: %@", self.video.videoId);
    NSLog(@"Title: %@", self.video.title);
    NSLog(@"Author: %@", self.video.author);
    NSLog(@"Views: %@", self.video.views);
    NSLog(@"Likes: %@", self.video.likes);
    NSLog(@"Published: %@", self.video.publishedAt);
    NSLog(@"Duration: %@", self.video.duration);
    NSLog(@"Description: %@", self.video.descriptionText);
}

- (NSString *)formattedDate:(NSString *)rawDate {
    
    NSDateFormatter *inputFormatter = [[NSDateFormatter alloc] init];
    inputFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    
    // Accept full datetime if present
    [inputFormatter setDateFormat:@"dd.MM.yyyy',' HH:mm:ss"];
    NSDate *date = [inputFormatter dateFromString:rawDate];
    
    // If the full format didn't match, try just the date
    if (!date) {
        [inputFormatter setDateFormat:@"dd.MM.yyyy"];
        date = [inputFormatter dateFromString:rawDate];
    }
    
    if (date) {
        NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
        outputFormatter.dateStyle = NSDateFormatterMediumStyle; // e.g., "Oct 25, 2009"
        outputFormatter.timeStyle = NSDateFormatterNoStyle;
        return [outputFormatter stringFromDate:date];
    }
    
    return rawDate; // fallback if parsing failed
}


- (NSString *)formattedDuration:(NSString *)duration {
    // Implement duration formatting (PT3M34S → 3:34)
    if (![duration isKindOfClass:[NSString class]] || duration.length < 3) {
        return duration;
    }
    
    if ([duration hasPrefix:@"PT"] && [duration hasSuffix:@"S"]) {
        NSString *timePart = [duration substringWithRange:NSMakeRange(2, duration.length-3)];
        NSInteger minutes = 0;
        NSInteger seconds = 0;
        
        @try {
            NSRange mRange = [timePart rangeOfString:@"M"];
            if (mRange.location != NSNotFound) {
                NSString *minutesStr = [timePart substringToIndex:mRange.location];
                minutes = [minutesStr integerValue];
                timePart = [timePart substringFromIndex:mRange.location + 1];
            }
            
            NSRange sRange = [timePart rangeOfString:@"S"];
            if (sRange.location != NSNotFound) {
                NSString *secondsStr = [timePart substringToIndex:sRange.location];
                seconds = [secondsStr integerValue];
            } else {
                // Handle case where there's just seconds without 'S' (though YouTube format should always have it)
                seconds = [timePart integerValue];
            }
            
            return [NSString stringWithFormat:@"%ld:%02ld", (long)minutes, (long)seconds];
        }
        @catch (NSException *exception) {
            NSLog(@"Error parsing duration: %@", exception);
            return duration;
        }
    }
    return duration;
}


- (void)playVideoWithURL:(NSURL *)videoURL {
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    
    // Just load the URL directly in webView
    NSURLRequest *request = [NSURLRequest requestWithURL:videoURL];
    [self.webView loadRequest:request];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    // Simple playback trigger without volume manipulation
    [webView stringByEvaluatingJavaScriptFromString:
     @"var v=document.getElementsByTagName('video')[0];"
     @"if(v){v.play();}"];
}

- (void)showErrorAlert:(NSString *)message {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

- (IBAction)closeButtonTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dealloc {
    [_videoExtractConnection cancel];
    [_metadataConnection cancel];
    
    NSError *audioError = nil;
    [[AVAudioSession sharedInstance] setActive:NO error:&audioError];
    if (audioError) {
        NSLog(@"Audio session deactivation error: %@", audioError);
    }
}


@end