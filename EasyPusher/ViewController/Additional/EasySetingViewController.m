//
//  EasySetingViewController.m
//  EasyPusher
//
//  Created by yingengyue on 2017/1/10.
//  Copyright © 2017年 phylony. All rights reserved.
//

#import "EasySetingViewController.h"

@interface EasySetingViewController ()<UITextFieldDelegate>

@end

@implementation EasySetingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    UITextField *ipTextField = [[UITextField alloc] initWithFrame:CGRectMake(80, 64, 200.0, 30.0)];
    ipTextField.tag = 1000;
    ipTextField.delegate = self;
    ipTextField.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"ConfigIP"];
    [self.view addSubview:ipTextField];
    
    UITextField *portTextField = [[UITextField alloc] initWithFrame:CGRectMake(80, 104, 200.0, 30.0)];
    portTextField.tag = 1001;
    portTextField.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"ConfigPORT"];
    portTextField.delegate = self;
    [self.view addSubview:portTextField];

    UIButton *saveBtn = [[UIButton alloc] initWithFrame:CGRectMake(80, 144, [UIScreen mainScreen].bounds.size.width - 160, 40.0)];
    saveBtn.backgroundColor = [UIColor lightGrayColor];
    [saveBtn setTitle:@"保存" forState:UIControlStateNormal];
    [saveBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [saveBtn addTarget:self action:@selector(saveIpAndPort) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:saveBtn];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}

- (void)saveIpAndPort{
    [self.view endEditing:YES];
    UITextField *ipConfig = (UITextField *)[self.view viewWithTag:1000];
    UITextField *portConfig = (UITextField *)[self.view viewWithTag:1001];
    [[NSUserDefaults standardUserDefaults] setObject:ipConfig.text forKey:@"ConfigIP"];
    [[NSUserDefaults standardUserDefaults] setObject:portConfig.text forKey:@"ConfigPORT"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
