//
//  AQTLabel.h
//  AquaTerm
//
//  Created by ppe on Wed May 16 2001.
//  Copyright (c) 2001, 2002 Aquaterm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AQTGraphic.h"

@interface AQTLabel : AQTGraphic /*" NSObject "*/
{
   NSAttributedString *string;		/*" The text (label, legend etc.) "*/
   NSString *fontName;
   float fontSize;
   NSPoint position;		/*" The position of the text "*/
   float angle;
   int justification;		/*" Justification with respect to the position of the text "*/
}
- (id)initWithAttributedString:(NSAttributedString *)aString position:(NSPoint)aPoint angle:(float)textAngle justification:(int)justify;
- (id)initWithString:(NSString *)aString position:(NSPoint)aPoint angle:(float)textAngle justification:(int)justify;
- (void)setFontName:(NSString *)newFontName;
- (void)setFontSize:(float)newFontSize;
@end
