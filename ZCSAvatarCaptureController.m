//
//  ZCSAvatarCaptureController.m
//  ZCSAvatarCaptureDemo
//
//  Created by Zane Shannon on 8/27/14.
//  Copyright (c) 2014 Zane Shannon. All rights reserved.
//

#import "ZCSAvatarCaptureController.h"
#import <AVFoundation/AVFoundation.h>

@interface ZCSAvatarCaptureController () {
	CGRect previousFrame;
}

@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic, strong) AVCaptureDevice *captureDevice;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
@property (nonatomic, assign) BOOL isCapturingImage;
@property (nonatomic, strong) UIImageView *capturedImageView;
@property (nonatomic, strong) UIImagePickerController *picker;
@property (nonatomic, strong) UIView *imageSelectedView;
@property (nonatomic, strong) UIImage *selectedImage;

- (void)startCapture;
- (void)endCapture;

@end

@implementation ZCSAvatarCaptureController

- (void)viewDidLoad {
	[super viewDidLoad];
	self.view.backgroundColor = [UIColor yellowColor];
	UITapGestureRecognizer *singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(startCapture)];
	[self.view addGestureRecognizer:singleTapGestureRecognizer];
	UIImageView *avatarView = [[UIImageView alloc] initWithFrame:self.view.frame];
	avatarView.image = self.image;
	avatarView.clipsToBounds = YES;
	avatarView.contentMode = UIViewContentModeScaleAspectFit;
	[self.view addSubview:avatarView];
}

- (void)startCapture {
	for (UIView *subview in [self.view.subviews copy]) [subview removeFromSuperview];
	previousFrame = self.view.frame;
	self.view.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
	// Do any additional setup after loading the view.
	self.captureSession = [[AVCaptureSession alloc] init];
	self.captureSession.sessionPreset = AVCaptureSessionPresetPhoto;

	self.capturedImageView = [[UIImageView alloc] init];
	self.capturedImageView.frame = self.view.frame; // just to even it out
	self.capturedImageView.backgroundColor = [UIColor clearColor];
	self.capturedImageView.userInteractionEnabled = YES;
	self.capturedImageView.contentMode = UIViewContentModeScaleAspectFill;

	self.captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
	self.captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
	self.captureVideoPreviewLayer.frame = self.view.frame;
	[self.view.layer addSublayer:self.captureVideoPreviewLayer];

	NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
	if (devices.count > 0) {
		self.captureDevice = devices[0];

		NSError *error = nil;
		AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:self.captureDevice error:&error];

		[self.captureSession addInput:input];

		self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
		NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG, AVVideoCodecKey, nil];
		[self.stillImageOutput setOutputSettings:outputSettings];
		[self.captureSession addOutput:self.stillImageOutput];

		if (self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft) {
			_captureVideoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
		} else if (self.interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
			_captureVideoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
		}

		UIButton *camerabutton = [[UIButton alloc]
			initWithFrame:CGRectMake(CGRectGetWidth(self.view.bounds) / 2 - 50, CGRectGetHeight(self.view.frame) - 100, 100, 100)];
		[camerabutton setImage:[UIImage imageNamed:@"PKImageBundle.bundle/take-snap"] forState:UIControlStateNormal];
		[camerabutton addTarget:self action:@selector(capturePhoto:) forControlEvents:UIControlEventTouchUpInside];
		[camerabutton setTintColor:[UIColor blueColor]];
		[camerabutton.layer setCornerRadius:20.0];
		[self.view addSubview:camerabutton];

		UIButton *flashbutton = [[UIButton alloc] initWithFrame:CGRectMake(5, 25, 30, 31)];
		[flashbutton setImage:[UIImage imageNamed:@"PKImageBundle.bundle/flash"] forState:UIControlStateNormal];
		[flashbutton setImage:[UIImage imageNamed:@"PKImageBundle.bundle/flashselected"] forState:UIControlStateSelected];
		[flashbutton addTarget:self action:@selector(flash:) forControlEvents:UIControlEventTouchUpInside];
		[self.view addSubview:flashbutton];

		UIButton *frontcamera = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.view.frame) - 50, 25, 47, 25)];
		[frontcamera setImage:[UIImage imageNamed:@"PKImageBundle.bundle/front-camera"] forState:UIControlStateNormal];
		[frontcamera addTarget:self action:@selector(showFrontCamera:) forControlEvents:UIControlEventTouchUpInside];
		[self.view addSubview:frontcamera];
	}

	UIButton *album =
		[[UIButton alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.view.frame) - 35, CGRectGetHeight(self.view.frame) - 40, 27, 27)];
	[album setImage:[UIImage imageNamed:@"PKImageBundle.bundle/library"] forState:UIControlStateNormal];
	[album addTarget:self action:@selector(showalbum:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:album];

	UIButton *cancel = [[UIButton alloc] initWithFrame:CGRectMake(5, CGRectGetHeight(self.view.frame) - 40, 32, 32)];
	[cancel setImage:[UIImage imageNamed:@"PKImageBundle.bundle/cancel"] forState:UIControlStateNormal];
	[cancel addTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:cancel];

	self.picker = [[UIImagePickerController alloc] init];
	self.picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
	self.picker.delegate = self;

	self.imageSelectedView = [[UIView alloc] initWithFrame:self.view.frame];
	[self.imageSelectedView setBackgroundColor:[UIColor clearColor]];
	[self.imageSelectedView addSubview:self.capturedImageView];
	UIView *overlayView =
		[[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.frame) - 60, CGRectGetWidth(self.view.frame), 60)];
	[overlayView setBackgroundColor:[UIColor colorWithWhite:0.2 alpha:0.9]];
	[self.imageSelectedView addSubview:overlayView];
	UIButton *selectPhotoButton = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetWidth(overlayView.frame) - 40, 20, 32, 32)];
	[selectPhotoButton setImage:[UIImage imageNamed:@"PKImageBundle.bundle/selected"] forState:UIControlStateNormal];
	[selectPhotoButton addTarget:self action:@selector(photoSelected:) forControlEvents:UIControlEventTouchUpInside];
	[overlayView addSubview:selectPhotoButton];

	UIButton *cancelSelectPhotoButton = [[UIButton alloc] initWithFrame:CGRectMake(5, 20, 32, 32)];
	[cancelSelectPhotoButton setImage:[UIImage imageNamed:@"PKImageBundle.bundle/cancel"] forState:UIControlStateNormal];
	[cancelSelectPhotoButton addTarget:self action:@selector(cancelSelectedPhoto:) forControlEvents:UIControlEventTouchUpInside];
	[overlayView addSubview:cancelSelectPhotoButton];

	[self.captureSession startRunning];
	[[UIApplication sharedApplication] setStatusBarHidden:YES];
}

- (void)endCapture {
	[self.captureSession stopRunning];
	[[UIApplication sharedApplication] setStatusBarHidden:NO];
	[self.captureVideoPreviewLayer removeFromSuperlayer];
	for (UIView *subview in [self.view.subviews copy]) {
		[subview removeFromSuperview];
	}
	self.view.frame = previousFrame;
	UIImageView *avatarView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(previousFrame), CGRectGetHeight(previousFrame))];
	avatarView.image = self.image;
	avatarView.clipsToBounds = YES;
	avatarView.contentMode = UIViewContentModeScaleAspectFill;
	[self.view addSubview:avatarView];
}

- (IBAction)capturePhoto:(id)sender {
	self.isCapturingImage = YES;
	AVCaptureConnection *videoConnection = nil;
	for (AVCaptureConnection *connection in _stillImageOutput.connections) {
		for (AVCaptureInputPort *port in [connection inputPorts]) {
			if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
				videoConnection = connection;
				break;
			}
		}
		if (videoConnection) {
			break;
		}
	}

	[self.stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection
							   completionHandler:^(CMSampleBufferRef imageSampleBuffer, NSError *error) {

								   if (imageSampleBuffer != NULL) {

									   NSData *imageData = [AVCaptureStillImageOutput
										   jpegStillImageNSDataRepresentation:imageSampleBuffer];
									   UIImage *capturedImage = [[UIImage alloc] initWithData:imageData scale:1];
									   self.isCapturingImage = NO;
									   self.capturedImageView.image = capturedImage;
									   [self.view addSubview:self.imageSelectedView];
									   self.selectedImage = capturedImage;
									   imageData = nil;
								   }
							   }];
}

- (IBAction)flash:(UIButton *)sender {
	if ([self.captureDevice isFlashAvailable]) {
		if (self.captureDevice.flashActive) {
			if ([self.captureDevice lockForConfiguration:nil]) {
				self.captureDevice.flashMode = AVCaptureFlashModeOff;
				[sender setTintColor:[UIColor grayColor]];
				[sender setSelected:NO];
			}
		} else {
			if ([self.captureDevice lockForConfiguration:nil]) {
				self.captureDevice.flashMode = AVCaptureFlashModeOn;
				[sender setTintColor:[UIColor blueColor]];
				[sender setSelected:YES];
			}
		}
		[self.captureDevice unlockForConfiguration];
	}
}

- (IBAction)showFrontCamera:(id)sender {
	if (self.isCapturingImage != YES) {
		if (self.captureDevice == [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo][0]) {
			// rear active, switch to front
			self.captureDevice = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo][1];

			[self.captureSession beginConfiguration];
			AVCaptureDeviceInput *newInput = [AVCaptureDeviceInput deviceInputWithDevice:self.captureDevice error:nil];
			for (AVCaptureInput *oldInput in self.captureSession.inputs) {
				[self.captureSession removeInput:oldInput];
			}
			[self.captureSession addInput:newInput];
			[self.captureSession commitConfiguration];
		} else if (self.captureDevice == [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo][1]) {
			// front active, switch to rear
			self.captureDevice = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo][0];
			[self.captureSession beginConfiguration];
			AVCaptureDeviceInput *newInput = [AVCaptureDeviceInput deviceInputWithDevice:self.captureDevice error:nil];
			for (AVCaptureInput *oldInput in self.captureSession.inputs) {
				[self.captureSession removeInput:oldInput];
			}
			[self.captureSession addInput:newInput];
			[self.captureSession commitConfiguration];
		}

		// Need to reset flash btn
	}
}
- (IBAction)showalbum:(id)sender {
	[self presentViewController:self.picker animated:YES completion:nil];
}

- (IBAction)photoSelected:(id)sender {
	self.image = self.selectedImage;
	if ([self.delegate respondsToSelector:@selector(imageSelected:)]) {
		[self.delegate imageSelected:self.image];
	}
	[self endCapture];
}

- (IBAction)cancelSelectedPhoto:(id)sender {
	[self.imageSelectedView removeFromSuperview];
}

- (IBAction)cancel:(id)sender {
	[self endCapture];
	if ([self.delegate respondsToSelector:@selector(imageSelectionCancelled)]) {
		[self.delegate imageSelectionCancelled];
	}
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	self.selectedImage = [info objectForKey:UIImagePickerControllerOriginalImage];

	[self dismissViewControllerAnimated:YES
				   completion:^{
					   self.capturedImageView.image = self.selectedImage;
					   
					   [self.view addSubview:self.imageSelectedView];
				   }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end