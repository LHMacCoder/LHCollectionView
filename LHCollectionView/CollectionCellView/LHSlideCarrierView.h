//
//  LHSlideCarrierView.h
//  LHCollectionView
//
//  Created by 浩  林 on 2019/2/24.
//  Copyright © 2019 linhao. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSInteger, LHCollectionViewItemHighlightState) {
    LHCollectionViewItemHighlightNone = 0,
    LHCollectionViewItemHighlightForSelection = 1,
    LHCollectionViewItemHighlightForDeselection = 2,
    LHCollectionViewItemHighlightAsDropTarget = 3,
};

#define SLIDE_WIDTH           140.0     // width  of the SlideCarrier image (which includes shadow margins) in points, and thus the width  that we give to a Slide's root view
#define SLIDE_HEIGHT          140.0     // height of the SlideCarrier image (which includes shadow margins) in points, and thus the height that we give to a Slide's root view

#define SLIDE_SHADOW_MARGIN    10.0     // margin on each side between the actual slide shape edge and the edge of the SlideCarrier image
#define SLIDE_CORNER_RADIUS     8.0     // corner radius of the slide shape in points
#define SLIDE_BORDER_WIDTH      4.0     // thickness of border when shown, in points

// A AAPLSlideCarrierView serves as the container view for each AAPLSlide item.  It displays a "SlideCarrier" slide shape image with built-in shadow, customizes hit-testing to account for the slide shape's rounded corners, and implements visual indication of item selection and highlighting state.
@interface LHSlideCarrierView : NSView
{
    LHCollectionViewItemHighlightState highlightState;
    BOOL selected;
}

// To leave the specifics of highlighted and selected appearance to the SlideCarrierView's implementation, we mirror NSCollectionViewItem's "highlightState" and "selected" properties to it.
@property LHCollectionViewItemHighlightState highlightState;
@property (getter=isSelected) BOOL selected;

@end
