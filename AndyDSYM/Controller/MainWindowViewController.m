//
//  MainWindowViewController.m
//  CustomModalWindow
//
//  Created by Andy on 9/16/19.
//  Copyright © 2019 Andy. All rights reserved.
//

#import "MainWindowViewController.h"
#import "DSYMInfo.h"
#import "UUIDInfo.h"


@interface MainWindowViewController ()<NSTableViewDelegate, NSTableViewDataSource, NSDraggingDestination>

/**
 *  显示 archive 文件的 tableView
 */
@property (weak) IBOutlet NSTableView *dSYMFilesTableView;

/**
 *  存放 radio 的 box
 */
@property (weak) IBOutlet NSBox *radioBox;

/**
 *  DSYM 文件信息数组
 */
@property (nonatomic, strong) NSMutableArray<DSYMInfo *> *dSYMFilesInfoArrM;

/**
 *  选中的 DSYM 文件信息
 */
@property (nonatomic, strong) DSYMInfo *selectedDSYMInfo;

/**
 * 选中的 UUID 信息
 */
@property (nonatomic, strong) UUIDInfo *selectedUUIDInfo;

/**
 *  显示选中的 CPU 类型对应可执行文件的 UUID
 */
@property (weak) IBOutlet NSTextField *selectedUUIDLabel;

/**
 *  显示默认的 Slide Address
 */
@property (weak) IBOutlet NSTextField *defaultSlideAddressLabel;

/**
 显示地址偏移地址
 */
@property (weak) IBOutlet NSTextField *baseAddressLabel;

/**
 *  显示错误内存地址
 */
@property (weak) IBOutlet NSTextField *errorMemoryAddressLabel;

/**
 *  错误信息
 */
@property (unsafe_unretained) IBOutlet NSTextView *errorMessageView;

@end

@implementation MainWindowViewController


- (void)windowDidLoad {
    [super windowDidLoad];
    
    [self.window registerForDraggedTypes:@[NSColorPboardType, NSFilenamesPboardType]];
}

/**
 *  处理给定dSYM文件路径，获取 DSYMinfo 对象
 *
 *  @param filePaths DSYM 文件路径
 */
- (void)handleDSYMFileWithPath:(NSArray *)filePaths
{
    _dSYMFilesInfoArrM = [NSMutableArray arrayWithCapacity:1];
    for (NSString *filePath in filePaths) {
        DSYMInfo *dSYMInfo = [[DSYMInfo alloc] init];
        NSString *fileName = filePath.lastPathComponent;
        if ([fileName hasSuffix:@".app.dSYM"])
        {
            dSYMInfo.dSYMFilePath = filePath;
            dSYMInfo.dSYMFileName = fileName;
            [self formatDSYM:dSYMInfo];
        }
        else
        {
            continue;
        }

        [_dSYMFilesInfoArrM addObject:dSYMInfo];
    }

    [self.dSYMFilesTableView reloadData];
}

/**
 * 根据 dSYM 文件获取 UUIDS。
 * @param dSYMInfo
 */
- (void)formatDSYM:(DSYMInfo *)dSYMInfo
{
    //匹配 () 里面内容
    NSString *pattern = @"(?<=\\()[^}]*(?=\\))";
    NSRegularExpression *reg = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
    NSString *commandString = [NSString stringWithFormat:@"dwarfdump --uuid \"%@\"",dSYMInfo.dSYMFilePath];
    NSString *uuidsString = [self runCommand:commandString];
    NSArray *uuids = [uuidsString componentsSeparatedByString:@"\n"];

    NSMutableArray *uuidInfos = [NSMutableArray arrayWithCapacity:1];
    for (NSString *uuidString in uuids) {
        NSArray* match = [reg matchesInString:uuidString options:NSMatchingReportCompletion range:NSMakeRange(0, [uuidString length])];
        if (match.count == 0)
        {
            continue;
        }
        for (NSTextCheckingResult *result in match) {
            NSRange range = [result range];
            UUIDInfo *uuidInfo = [[UUIDInfo alloc] init];
            uuidInfo.arch = [uuidString substringWithRange:range];
            uuidInfo.uuid = [uuidString substringWithRange:NSMakeRange(6, range.location-6-2)];
            uuidInfo.executableFilePath = [uuidString substringWithRange:NSMakeRange(range.location+range.length+2, [uuidString length]-(range.location+range.length+2))];
            [uuidInfos addObject:uuidInfo];
        }
        dSYMInfo.uuidInfos = uuidInfos;
    }
}

- (NSString *)runCommand:(NSString *)commandToRun
{
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/bin/sh"];
    
    NSArray *arguments = @[@"-c", [NSString stringWithFormat:@"%@", commandToRun]];
//    NSLog(@"run command:%@", commandToRun);
    [task setArguments:arguments];
    
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    
    NSFileHandle *file = [pipe fileHandleForReading];
    
    [task launch];
    
    NSData *data = [file readDataToEndOfFile];
    
    NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return output;
}


#pragma mark - NSTableViewDataSources
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [_dSYMFilesInfoArrM count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    DSYMInfo *archiveInfo= _dSYMFilesInfoArrM[row];
    return archiveInfo.dSYMFileName;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{

    DSYMInfo *archiveInfo= _dSYMFilesInfoArrM[row];
    NSString *identifier = tableColumn.identifier;
    NSView *view = [tableView makeViewWithIdentifier:identifier owner:self];
    NSArray *subviews = view.subviews;
    if (subviews.count > 0)
    {
        if ([identifier isEqualToString:@"name"])
        {
            NSTextField *textField = subviews[0];
            textField.stringValue = archiveInfo.dSYMFileName;
        }
    }
    return view;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSInteger row = [notification.object selectedRow];
    _selectedDSYMInfo= _dSYMFilesInfoArrM[row];
    [self resetPreInformation];

    CGFloat radioButtonWidth = CGRectGetWidth(self.radioBox.contentView.frame);
    CGFloat radioButtonHeight = 18;
    [_selectedDSYMInfo.uuidInfos enumerateObjectsUsingBlock:^(UUIDInfo *uuidInfo, NSUInteger idx, BOOL *stop) {
        CGFloat space = (CGRectGetHeight(self.radioBox.contentView.frame) - _selectedDSYMInfo.uuidInfos.count * radioButtonHeight) / (_selectedDSYMInfo.uuidInfos.count + 1);
        CGFloat y = space * (idx + 1) + idx * radioButtonHeight;
        NSButton *radioButton = [[NSButton alloc] initWithFrame:NSMakeRect(10,y,radioButtonWidth,radioButtonHeight)];
        [radioButton setButtonType:NSRadioButton];
        [radioButton setTitle:uuidInfo.arch];
        radioButton.tag = idx + 1;
        [radioButton setAction:@selector(radioButtonAction:)];
        [self.radioBox.contentView addSubview:radioButton];
    }];
}

/**
 * 重置之前显示的信息
 */
- (void)resetPreInformation
{
    [self.radioBox.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    _selectedUUIDInfo = nil;
    self.selectedUUIDLabel.stringValue = @"";
    self.defaultSlideAddressLabel.stringValue = @"";
    self.errorMemoryAddressLabel.stringValue = @"";
    [self.errorMessageView setString:@""];
}

- (void)radioButtonAction:(id)sender
{
    NSButton *radioButton = sender;
    NSInteger tag = radioButton.tag;
    _selectedUUIDInfo = _selectedDSYMInfo.uuidInfos[tag - 1];
    _selectedUUIDLabel.stringValue = _selectedUUIDInfo.uuid;
    _defaultSlideAddressLabel.stringValue = _selectedUUIDInfo.defaultSlideAddress;
}

- (IBAction)analyse:(id)sender
{
    if(self.selectedDSYMInfo == nil) return;
    
    if(self.selectedUUIDInfo == nil) return;
    
    if([self.defaultSlideAddressLabel.stringValue isEqualToString:@""]) return;
    
    if ([self.baseAddressLabel.stringValue isEqualToString:@""]) return;
    
    if([self.errorMemoryAddressLabel.stringValue isEqualToString:@""]) return;
    
    // 计算偏移量，计算出在DSYM中真实的代码地址
    NSInteger slideAddressDec = [self hex2Dec:self.defaultSlideAddressLabel.stringValue].integerValue;
    NSInteger baseAddressDec = [self hex2Dec:self.baseAddressLabel.stringValue].integerValue;
    NSInteger addr_offset = baseAddressDec - slideAddressDec;
    NSInteger real_addr = [self hex2Dec:self.errorMemoryAddressLabel.stringValue].integerValue - addr_offset;
    NSString *real_addr_hex = [self dec2Hex:real_addr];
    
    NSString *commandString = [NSString stringWithFormat:@"xcrun atos -arch %@ -o \"%@\" -l %@ %@", self.selectedUUIDInfo.arch, self.selectedUUIDInfo.executableFilePath, self.defaultSlideAddressLabel.stringValue, real_addr_hex];
    NSString *result = [self runCommand:commandString];
    [self.errorMessageView setString:result];
}

//将十进制转化为十六进制
- (NSString *)dec2Hex:(long long int)tmpid
{
    NSString *nLetterValue;
    NSString *str = @"";
    long long int ttmpig;
    for (int i = 0; i < 9; i++) {
        ttmpig = tmpid%16;
        tmpid = tmpid/16;
        switch (ttmpig)
        {
            case 10:
                nLetterValue = @"A";break;
            case 11:
                nLetterValue = @"B";break;
            case 12:
                nLetterValue = @"C";break;
            case 13:
                nLetterValue = @"D";break;
            case 14:
                nLetterValue = @"E";break;
            case 15:
                nLetterValue = @"F";break;
            default:nLetterValue = [[NSString alloc] initWithFormat:@"%lli",ttmpig];
                
        }
        str = [nLetterValue stringByAppendingString:str];
        if (tmpid == 0) {
            break;
        }
        
    }
    return str;
}

//十六进制->十进制
- (NSString *)hex2Dec:(NSString *)hexStr
{
    NSString *temp = [NSString stringWithFormat:@"%lu", strtoul([hexStr UTF8String],0,16)];
    return temp;
}

#pragma mark - support drag
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;

    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];

    if ([[pboard types] containsObject:NSColorPboardType])
    {
        if (sourceDragMask & NSDragOperationGeneric)
        {
            return NSDragOperationGeneric;
        }
    }
    if ([[pboard types] containsObject:NSFilenamesPboardType])
    {
        if (sourceDragMask & NSDragOperationLink)
        {
            return NSDragOperationLink;
        }
        else if (sourceDragMask & NSDragOperationCopy)
        {
            return NSDragOperationCopy;
        }
    }
    return NSDragOperationNone;
}


- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSPasteboard *pboard = [sender draggingPasteboard];

    if ([[pboard types] containsObject:NSURLPboardType])
    {
        NSURL *fileURL = [NSURL URLFromPasteboard:pboard];
        NSLog(@"%@",fileURL);
    }

    if ([[pboard types] containsObject:NSFilenamesPboardType])
    {
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
        NSMutableArray *dSYMFilePaths = [NSMutableArray arrayWithCapacity:1];
        for (NSString *filePath in files) {
            if ([filePath.pathExtension isEqualToString:@"dSYM"])
            {
                [dSYMFilePaths addObject:filePath];
            }
        }
        
        if (dSYMFilePaths.count == 0)
        {
            NSLog(@"没有包含任何 dSYM 文件");
            return NO;
        }
        
        [self resetPreInformation];

        [self handleDSYMFileWithPath:dSYMFilePaths];
    }
    return YES;
}

@end
