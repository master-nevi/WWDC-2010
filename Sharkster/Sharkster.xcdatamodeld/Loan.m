/*
     File: Loan.m
 Abstract: Represents the Loan entity in our data model.
  Version: 1.1
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2010 Apple Inc. All Rights Reserved.
 
 */

#import "Loan.h"

#import "Payment.h"

//a constant for the NSTimeInterval representing one day in seconds
static NSTimeInterval const oneDay = 86400;

@implementation Loan 

@dynamic principal;
@dynamic startDate;
@dynamic personID;
@dynamic timeStamp;
@dynamic identifier;
@dynamic length;
@dynamic interestRate;
@dynamic payments;
@dynamic paymentFrequency;

- (NSNumber *)totalAmount {
    float totalAmount = [self.interest floatValue] + [self.principal floatValue];
    return [NSNumber numberWithFloat:totalAmount];
}

- (NSNumber *)interest {
    float interestAmount = [self.interestRate floatValue] * [self.principal floatValue];
    return [NSNumber numberWithFloat:interestAmount];
}

- (NSString *)paymentAmountForNumberOfPayments:(int)numberOfPayments {
    float paymentAmount = [self.totalAmount floatValue] / (float) numberOfPayments;
    NSNumberFormatter * formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    NSString * paymentString = [formatter stringFromNumber:[NSNumber numberWithFloat:paymentAmount]];
    [formatter release];
    
    return paymentString;
}

- (int)expectedNumberOfPayments {
    int paymentCount = 1;
    
    BOOL pastEndDate = NO;
    NSDate * endDate = self.endDate;
    while (!pastEndDate) {
        NSDate * paymentDate = [self expectedDateForPaymentNumber:paymentCount];
        
        NSComparisonResult comparison = [endDate compare:paymentDate];
        if (comparison == NSOrderedAscending) {
            //endDate is earlier
            pastEndDate = YES;
            //we went past the end date, which is too far, back off the count by 1
            paymentCount--;
        } else {
            paymentCount++;
        }
    }
    //we always have at least one payment
    paymentCount = (paymentCount==0) ? 1 : paymentCount;
    return paymentCount;
}

- (NSDate *)endDate {
    NSCalendar * calendar = [NSCalendar currentCalendar];
    NSDateComponents * components = [[NSDateComponents alloc] init];
    switch ([self.length intValue]) {
        case LoanLength3Days:
            [components setDay:3];
            break;
        case LoanLength1Week:
            [components setWeek:1];
            break;
        case LoanLength2Weeks:
            [components setWeek:2];
            break;
        case LoanLength3Weeks:
            [components setWeek:3];
            break;
        case LoanLength1Month:
            [components setMonth:1];
            break;
        case LoanLength3Months:
            [components setMonth:3];
            break;
        case LoanLength6Months:
            [components setMonth:6];
            break;
        case LoanLength9Months:
            [components setMonth:9];
            break;
        case LoanLength1Year:
            [components setYear:1];
            break;
        case LoanLength2Years:
            [components setYear:2];
            break;
        case LoanLength3Years:
            [components setYear:3];
            break;
        default:
            //we'll default to tomorrow to avoid any infinite payment counts
            [components setDay:1];
            break;
    }
    NSDate * endDate = [calendar dateByAddingComponents:components toDate:self.startDate options:0];
    [components release];
    return endDate;
}

- (NSDate *)firstPaymentDate {
    return [self expectedDateForPaymentNumber:1];
}

- (NSDate *)expectedDateForPaymentNumber:(int)paymentNumber {
    NSCalendar * calendar = [NSCalendar currentCalendar];
    NSDateComponents * components = [[NSDateComponents alloc] init];
    
    switch ([self.paymentFrequency intValue]) {
        case LoanPaymentFrequencyDaily:
            [components setDay:1 * paymentNumber];
            break;
        case LoanPaymentFrequency3Days:
            [components setDay:3 * paymentNumber];
            break;
        case LoanPaymentFrequencyWeekly:
            [components setWeek:1 * paymentNumber];
            break;
        case LoanPaymentFrequencyBiweekly:
            [components setWeek:2 * paymentNumber];
            break;
        case LoanPaymentFrequencyMonthly:
            [components setMonth:1 * paymentNumber]; 
            break;
        case LoanPaymentFrequency3Months:
            [components setMonth:3 * paymentNumber]; 
            break;
        case LoanPaymentFrequency6Months:
            [components setMonth:6 * paymentNumber]; 
            break;
        case LoanPaymentFrequencyYearly:
            [components setYear:1 * paymentNumber]; 
            break;
        default:
            [components setMonth:1 * paymentNumber];
            break;
    }
    
    NSDate * paymentDate = [calendar dateByAddingComponents:components toDate:self.startDate options:0];
    [components release];
    
    return paymentDate;
}

//returning nil means it's the same as the other payments
- (NSString *)lastPaymentAmountForNumberOfPayments:(int)numberOfPayments {
    NSString * lastPaymentAmountString = nil;
    NSNumberFormatter * formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    NSNumber * paymentAmount = [formatter numberFromString:[self paymentAmountForNumberOfPayments:numberOfPayments]];
    float lastPaymentRemainder = [self.totalAmount floatValue] - ([paymentAmount floatValue] * (float)numberOfPayments);
    
    if (lastPaymentRemainder != 0.0) {
        NSNumber * lastPaymentAmount = [NSNumber numberWithFloat:[paymentAmount floatValue] + lastPaymentRemainder];
        lastPaymentAmountString = [[[formatter stringFromNumber:lastPaymentAmount] retain] autorelease];
    }
    
    [formatter release];
    return lastPaymentAmountString;
}

- (BOOL)hasDifferentLastPaymentForNumberOfPayments:(int)numberOfPayments {
    return ([self lastPaymentAmountForNumberOfPayments:numberOfPayments]) ? YES : NO;
}

- (NSArray *)orderedPayments {
    NSSortDescriptor * sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"paymentNumber" ascending:YES];
    NSArray * orderedPayments = [self.payments sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    return orderedPayments;
}

- (NSArray *)paymentsSortedByDate {
    NSSortDescriptor * sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES];
    NSArray * orderedPayments = [self.payments sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    return orderedPayments; 
}

- (Payment *)nextPayment {
    //next payment info
    NSArray * orderedPayments = [self paymentsSortedByDate];
    NSDate * today = [[NSDate alloc] init];
    Payment * nextPayment = nil;
    
    //find the next payment date
    
    for (Payment * payment in orderedPayments) {
        NSTimeInterval interval = [payment.date timeIntervalSinceDate:today];
        if (interval > -oneDay) {
            nextPayment = payment;
            break;
        }
    }
    
    [today release];
    
    return nextPayment;
}


@end
