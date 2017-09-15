//
//  XDY_ChoicePictureVC.m
//  XDYSDKDemo
//
//  Created by lyy on 2017/7/23.
//  Copyright © 2017年 liyanyan. All rights reserved.
//


#import "XDY_ChoicePictureVC.h"
#import "XDY_PhotoListCell.h"
#import "XDY_Asset.h"

#define kWHC_ShowPictureWidth     (80)           //默认展示宽度为80
#define kWHC_CellName             (@"WHC_ChoicePictureVC")

#define kChoiceTitle              (@"已选择(%d / %d)")
@interface XDY_ChoicePictureVC ()<XDY_PhotoListCellDelegate>{
    NSMutableArray         * _assetArr;          //相册集合
    NSInteger                _listColumn;        //列表列
    BOOL                     _choiceState;       //选择的状态
    
    
    __weak  typeof(XDY_ChoicePictureVC)     * _sf;
}

@property (nonatomic , strong)IBOutlet  UITableView   * pictureTV;

@end

@implementation XDY_ChoicePictureVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = [NSString stringWithFormat:kChoiceTitle , (int)self.maxChoiceImageNumber , 0];
    [self initData];
    [self layoutUI];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self performSelectorInBackground:@selector(scanPhoto) withObject:Nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)layoutUI{
    UIBarButtonItem  * doneBarItem = [[UIBarButtonItem alloc]initWithTitle:@"完成" style:UIBarButtonItemStyleDone target:self action:@selector(clickDone:)];
    doneBarItem.tintColor = [UIColor grayColor];
    self.navigationItem.rightBarButtonItem = doneBarItem;
}

- (void)initData{
    _sf = self;
    _assetArr = [NSMutableArray new];
    _listColumn = CGRectGetWidth([UIScreen mainScreen].bounds) / kWHC_ShowPictureWidth;
}

- (void)scanPhoto{
    if(_assetsGroup){
        [_assetsGroup enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
            if(result){
                XDY_Asset  * whcAS = [[XDY_Asset alloc]initWithAsset:result];
                [_assetArr addObject:whcAS];
            }
        }];
        dispatch_sync(dispatch_get_main_queue(), ^{
            [_pictureTV reloadData];
        });
    }
}

- (NSArray *)getRowAssets:(NSInteger)row{
    NSInteger index = row * _listColumn;
    NSInteger length = MIN(_listColumn, [_assetArr count] - index);
    return [_assetArr subarrayWithRange:NSMakeRange(index, length)];
}

- (void)clickDone:(UIBarButtonItem *)sender{
    NSMutableArray  *  selectedImageArr = [NSMutableArray array];
    for (XDY_Asset * whcAS in _assetArr) {
        if(whcAS.selected) {
            [selectedImageArr addObject:whcAS];
        }
    }
    [self performSelectorInBackground:@selector(selectedAssets:) withObject:selectedImageArr];
}

-(void)selectedAssets:(NSArray*)assets{
    
    NSMutableArray  * imageArr = [NSMutableArray array];
    for (XDY_Asset  * whcAS in assets) {
        ALAssetRepresentation  * representation = [whcAS.asset defaultRepresentation];
        CGImageRef  imageRef = [representation fullResolutionImage];
        UIImage    * image = [UIImage imageWithCGImage:imageRef scale:0 orientation:(UIImageOrientation)representation.orientation];
        [imageArr addObject:image];
    }
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated:YES completion:^{
            if(_delegate){
                if([_delegate respondsToSelector:@selector(XDYChoicePictureVC:didSelectedPhotoArr:)]){
                    [_delegate XDYChoicePictureVC:_sf didSelectedPhotoArr:imageArr];
                }
            }
        }];
    });
}

- (NSInteger)getChoicedImageCount{
    NSInteger count = 0;
    for (XDY_Asset * whcAS in _assetArr) {
        if(whcAS.selected) {
            ++count;
        }
    }
    return count;
}

#pragma mark - XDY_PhotoListCellDelegate
- (BOOL)XDYPhotoListCurrentChoiceState:(BOOL)selected{
    BOOL isChoiced = NO;
    NSInteger count = [self getChoicedImageCount];
    if (selected) {
        self.navigationItem.title = [NSString stringWithFormat:kChoiceTitle ,(int)self.maxChoiceImageNumber , (int)count - 1];
    }else if (self.maxChoiceImageNumber > count){
        self.navigationItem.title = [NSString stringWithFormat:kChoiceTitle ,(int)self.maxChoiceImageNumber , (int)count + 1];
        isChoiced = YES;
    }
    return isChoiced;
}

- (void)WHCPhotoListCancelChoicePhoto{
    _choiceState = NO;
}

#pragma mark - UITableViewDelegate UITableViewDataSource

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return [XDY_PhotoListCell cellHeight];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    return [UIView new];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return ceil((CGFloat)(_assetArr.count) / (CGFloat)_listColumn);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    XDY_PhotoListCell * cell = [tableView dequeueReusableCellWithIdentifier:kWHC_CellName];
    if(cell == nil){
        cell = [[XDY_PhotoListCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kWHC_CellName];
    }
    cell.delegate = self;
    cell.listColumn = _listColumn;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    [cell setAssets:[self getRowAssets:indexPath.row]];
    return cell;
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
