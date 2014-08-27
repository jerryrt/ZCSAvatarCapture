//
//  ViewController.m
//  ZCSAvatarCaptureDemo
//
//  Created by Zane Shannon on 8/27/14.
//  Copyright (c) 2014 Zane Shannon. All rights reserved.
//

#import "ViewController.h"
#import "ZCSAvatarCaptureController.h"

@interface ViewController ()

@property (strong, nonatomic) ZCSAvatarCaptureController *avatarCaptureController;

@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	self.avatarCaptureController = [[ZCSAvatarCaptureController alloc] init];
	self.avatarCaptureController.delegate = self;
	self.avatarCaptureController.view.frame = self.avatarView.frame;
	[self.view addSubview:self.avatarCaptureController.view];
}

- (void)imageSelected:(UIImage *)image {
	NSLog(@"imageSelected: %@", image);
}

- (void)imageSelectionCancelled {
	NSLog(@"imageSelectionCancelled");
}

@end