#import "PanelController.h"
#import "BackgroundView.h"
#import "StatusItemView.h"
#import "MenubarController.h"
#import "JSONKit.h"

#define OPEN_DURATION .15
#define CLOSE_DURATION .1

#define SEARCH_INSET 17

#define POPUP_HEIGHT 200
#define PANEL_WIDTH 280
#define MENU_ANIMATION_DURATION .1

#pragma mark -

@implementation PanelController

@synthesize backgroundView = _backgroundView;
@synthesize delegate = _delegate;
@synthesize searchField = _searchField;
@synthesize textField = _textField;

#pragma mark -

- (id)initWithDelegate:(id<PanelControllerDelegate>)delegate
{
    self = [super initWithWindowNibName:@"Panel"];
    if (self != nil)
    {
        _delegate = delegate;
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSControlTextDidChangeNotification object:self.searchField];
}

#pragma mark -

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // Make a fully skinned panel
    NSPanel *panel = (id)[self window];
    [panel setAcceptsMouseMovedEvents:YES];
    [panel setLevel:NSPopUpMenuWindowLevel];
    [panel setOpaque:NO];
    [panel setBackgroundColor:[NSColor clearColor]];
    
    // Resize panel
    NSRect panelRect = [[self window] frame];
    panelRect.size.height = POPUP_HEIGHT;
    [[self window] setFrame:panelRect display:NO];
    
    // Follow search string
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(runSearch) name:NSControlTextDidChangeNotification object:self.searchField];
    
    langStr = @"hl=hu&sl=en&tl=hu";
}

#pragma mark - Public accessors

- (BOOL)hasActivePanel
{
    return _hasActivePanel;
}

- (void)setHasActivePanel:(BOOL)flag
{
    if (_hasActivePanel != flag)
    {
        _hasActivePanel = flag;
        
        if (_hasActivePanel)
        {
            [self openPanel];
        }
        else
        {
            [self closePanel];
        }
    }
}

#pragma mark - NSWindowDelegate

- (void)windowWillClose:(NSNotification *)notification
{
    self.hasActivePanel = NO;
}

- (void)windowDidResignKey:(NSNotification *)notification;
{
    if ([[self window] isVisible])
    {
        self.hasActivePanel = NO;
    }
}

- (void)windowDidResize:(NSNotification *)notification
{
    NSWindow *panel = [self window];
    NSRect statusRect = [self statusRectForWindow:panel];
    NSRect panelRect = [panel frame];
    
    CGFloat statusX = roundf(NSMidX(statusRect));
    CGFloat panelX = statusX - NSMinX(panelRect);
    
    self.backgroundView.arrowX = panelX;
    
    NSRect searchRect = [self.searchField frame];
    searchRect.size.width = NSWidth([self.backgroundView bounds]) - SEARCH_INSET * 2;
    searchRect.origin.x = SEARCH_INSET+5;
    searchRect.origin.y = NSHeight([self.backgroundView bounds]) - ARROW_HEIGHT - SEARCH_INSET - NSHeight(searchRect);
    
    if (NSIsEmptyRect(searchRect))
    {
        [self.searchField setHidden:YES];
    }
    else
    {
        [self.searchField setFrame:searchRect];
        [self.searchField setHidden:NO];
    }
    
    NSRect textRect = [self.textField frame];
    textRect.size.width = NSWidth([self.backgroundView bounds]) - SEARCH_INSET * 2;
    textRect.origin.x = SEARCH_INSET;
    textRect.size.height = NSHeight([self.backgroundView bounds]) - ARROW_HEIGHT - SEARCH_INSET * 3 - NSHeight(searchRect);
    textRect.origin.y = SEARCH_INSET*-0.3;
    
    if (NSIsEmptyRect(textRect))
    {
        [self.textField setHidden:YES];
    }
    else
    {
        [self.textField setFrame:textRect];
        [self.textField setHidden:NO];
    }
}

#pragma mark - Keyboard

- (void)cancelOperation:(id)sender
{
    self.hasActivePanel = NO;
}

- (void)runSearch
{
    NSString *searchFormat = @"";
    NSString *searchString = [self.searchField stringValue];
    if ([searchString length] > 0)
    {
        searchFormat = NSLocalizedString(@"Forditás for ‘%@’…", @"Format for search request");
        //NSString *searchRequest = [NSString stringWithFormat:searchFormat, searchString];
        
        NSString *urlStr = [NSString stringWithFormat:@"http://translate.google.com/translate_a/t?client=t&text=%@&%@&ie=UTF-8&oe=UTF-8&multires=1&otf=2&ssel=0&tsel=0&sc=1",[searchString stringByReplacingOccurrencesOfString:@" " withString:@"%20"],langStr];
        urlStr = [urlStr lowercaseString];
        urlStr = [urlStr stringByReplacingOccurrencesOfString:@"á" withString:@"%C3%A1"];
        urlStr = [urlStr stringByReplacingOccurrencesOfString:@"é" withString:@"%C3%A9"];
        urlStr = [urlStr stringByReplacingOccurrencesOfString:@"ő" withString:@"%C5%91"];
        urlStr = [urlStr stringByReplacingOccurrencesOfString:@"ú" withString:@"%C3%BA"];
        urlStr = [urlStr stringByReplacingOccurrencesOfString:@"ű" withString:@"%C5%B1"];
        urlStr = [urlStr stringByReplacingOccurrencesOfString:@"ó" withString:@"%C3%B3"];
        urlStr = [urlStr stringByReplacingOccurrencesOfString:@"ö" withString:@"%C3%B6"];
        urlStr = [urlStr stringByReplacingOccurrencesOfString:@"ü" withString:@"%C3%BC"];
        urlStr = [urlStr stringByReplacingOccurrencesOfString:@"í" withString:@"%C3%AD"];        
        
        
        //translate.google.com/translate_a/t?client=t&text=sticky%20note&hl=hu&sl=en&tl=hu&ie=UTF-8&oe=UTF-8&multires=1&otf=2&ssel=5&tsel=5&sc=1
        //translate.google.com/translate_a/t?client=t&text=sticky%20note&hl=hu&sl=hu&tl=en&ie=utf-8&oe=utf-8&multires=1&otf=2&ssel=0&tsel=0&sc=1

        
        //á-é-ő-ú-ű-ó-ö-ü
        //translate.google.com/translate_a/t?client=t&text=%C3%A1-%C3%A9-%C5%91-%C3%BA-%C5%B1-%C3%B3-%C3%B6-%C3%BC&hl=hu&sl=hu&tl=en&ie=UTF-8&oe=UTF-8&multires=1&otf=2&ssel=5&tsel=5&sc=1
        
        
        NSLog(@"%@",urlStr);
        
        [self.textField setStringValue:@""];
        [self.loader startAnimation:self.loader];
        [self.loader setHidden:FALSE];
        
        //[[self window] setFrame:NSRectFromCGRect(CGRectMake([self window].frame.origin.x, [self window].frame.origin.y, 200, 400)) display:YES];
        

        
        //Create the URL request
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlStr]];
        
        //Start the request for the data
        [NSURLConnection sendAsynchronousRequest:request queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
            //If data were received
            if (data) {
                //Convert to string
                NSString *result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                //Create view controller and set its result/product/version

                NSLog(@"res: %@",result);
                
                NSError* error = nil;
                
                NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"(\\[\"[a-zA-záéűúöőóüí ]*\",\\[(\"[a-zA-záéűöúőóüí ]*\",?)*\\],?)" options:0 error:&error];

                NSArray* matches = [regex matchesInString:result options:0 range:NSMakeRange(0, [result length])];
                
                //NSLog(@"matches:%@",matches);
                
                
                NSString *oldStr = [self.textField stringValue];

                if ([matches count]==0){
                    NSLog(@"nincs talat");
                    
                    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"(\\[\\[(\"[a-zA-záéűúőóüí ]*\",?)*\\],?\\])" options:0 error:&error];
                    
                    
                    //ez jo
                    //@"(\\[\\[(\"[a-zA-záéűúőóüí ]*\",?)*\\],?\\])
                    
                    //ez a kiegészites
                    // |\\[\"[a-zA-záéűöúőóüí ]*\",[0-9]*,\\[[\\[\"[a-zA-záéűúőóüíö ]*\",[0-9]*,[0-9]*,[0-9]*\\],?]*)
                    
                    matches = [regex matchesInString:result options:0 range:NSMakeRange(0, [result length])];
                    
                    NSLog(@"matches2:%@",matches);

                    
                }
                
                for ( NSTextCheckingResult* match in matches )
                {
                    NSString* matchText = [result substringWithRange:[match range]];
                    NSLog(@"match: %@", matchText);
                    NSString *outputStr = [matchText stringByReplacingOccurrencesOfString:@"[" withString:@""];
                    outputStr = [outputStr stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                    outputStr = [outputStr stringByReplacingOccurrencesOfString:@"]" withString:@""];
                    NSArray *myWords = [outputStr componentsSeparatedByCharactersInSet:
                                        [NSCharacterSet characterSetWithCharactersInString:@","]
                                        ];
                    for (int i=0; i<[myWords count]; i++){
                        if (![[myWords objectAtIndex:i] isEqualToString:@""] &&
                            ![[myWords objectAtIndex:i] isEqualToString:@"en"] &&
                            ![[myWords objectAtIndex:i] isEqualToString:@"hu"]
                            ){
                            oldStr = [oldStr stringByAppendingFormat:@"%@",[myWords objectAtIndex:i]];
                            if (i==0) oldStr = [oldStr stringByAppendingFormat:@": "];
                                else if (i<[myWords count]-2) oldStr = [oldStr stringByAppendingFormat:@", "];
                        }
                    }
                    oldStr = [oldStr stringByAppendingFormat:@"\n"];
                }
                [self.textField setStringValue:oldStr];

                [self.loader stopAnimation:self.loader];
                [self.loader setHidden:TRUE];
            }}];
    }
    else {
        [self.textField setStringValue:@"Empty searchbox"];
        [self.loader stopAnimation:self.loader];
        [self.loader setHidden:TRUE];
    }
    
}

#pragma mark - Public methods

- (NSRect)statusRectForWindow:(NSWindow *)window
{
    NSRect screenRect = [[[NSScreen screens] objectAtIndex:0] frame];
    NSRect statusRect = NSZeroRect;
    
    StatusItemView *statusItemView = nil;
    if ([self.delegate respondsToSelector:@selector(statusItemViewForPanelController:)])
    {
        statusItemView = [self.delegate statusItemViewForPanelController:self];
    }
    
    if (statusItemView)
    {
        statusRect = statusItemView.globalRect;
        statusRect.origin.y = NSMinY(statusRect) - NSHeight(statusRect);
    }
    else
    {
        statusRect.size = NSMakeSize(STATUS_ITEM_VIEW_WIDTH, [[NSStatusBar systemStatusBar] thickness]);
        statusRect.origin.x = roundf((NSWidth(screenRect) - NSWidth(statusRect)) / 2);
        statusRect.origin.y = NSHeight(screenRect) - NSHeight(statusRect) * 2;
    }
    return statusRect;
}

- (void)openPanel
{
    NSWindow *panel = [self window];
    
    NSRect screenRect = [[[NSScreen screens] objectAtIndex:0] frame];
    NSRect statusRect = [self statusRectForWindow:panel];

    NSRect panelRect = [panel frame];
    panelRect.size.width = PANEL_WIDTH;
    panelRect.origin.x = roundf(NSMidX(statusRect) - NSWidth(panelRect) / 2);
    panelRect.origin.y = NSMaxY(statusRect) - NSHeight(panelRect);
    
    if (NSMaxX(panelRect) > (NSMaxX(screenRect) - ARROW_HEIGHT))
        panelRect.origin.x -= NSMaxX(panelRect) - (NSMaxX(screenRect) - ARROW_HEIGHT);
    
    [NSApp activateIgnoringOtherApps:NO];
    [panel setAlphaValue:0];
    [panel setFrame:statusRect display:YES];
    [panel makeKeyAndOrderFront:nil];
    
    NSTimeInterval openDuration = OPEN_DURATION;
    
    NSEvent *currentEvent = [NSApp currentEvent];
    if ([currentEvent type] == NSLeftMouseDown)
    {
        NSUInteger clearFlags = ([currentEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask);
        BOOL shiftPressed = (clearFlags == NSShiftKeyMask);
        BOOL shiftOptionPressed = (clearFlags == (NSShiftKeyMask | NSAlternateKeyMask));
        if (shiftPressed || shiftOptionPressed)
        {
            openDuration *= 10;
            
            if (shiftOptionPressed)
                NSLog(@"Icon is at %@\n\tMenu is on screen %@\n\tWill be animated to %@",
                      NSStringFromRect(statusRect), NSStringFromRect(screenRect), NSStringFromRect(panelRect));
        }
    }
    
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:openDuration];
    [[panel animator] setFrame:panelRect display:YES];
    [[panel animator] setAlphaValue:1];
    [NSAnimationContext endGrouping];
    
    [panel performSelector:@selector(makeFirstResponder:) withObject:self.searchField afterDelay:openDuration];
}

- (void)closePanel
{
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:CLOSE_DURATION];
    [[[self window] animator] setAlphaValue:0];
    [NSAnimationContext endGrouping];
    
    dispatch_after(dispatch_walltime(NULL, NSEC_PER_SEC * CLOSE_DURATION * 2), dispatch_get_main_queue(), ^{
        
        [self.window orderOut:nil];
    });
}

-(IBAction)switchLang:(id)sender{
    if ([langStr isEqualToString:@"hl=hu&sl=en&tl=hu"]) {
        langStr = @"hl=hu&sl=hu&tl=en";
        [self.switcherBtn setTitle:@"Magyar->Angol"];
    }
    else {
        [self.switcherBtn setTitle:@"Angol->Magyar"];
        langStr = @"hl=hu&sl=en&tl=hu";
    }
    [self runSearch];
}

@end
