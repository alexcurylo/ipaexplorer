//
//  TWXNSIndexSet.m
//
//  Copyright 2009 Trollwerks Inc. All rights reserved.
//

#import "TWXNSIndexSet.h"

@implementation TWIndexSetEnumerator

- (id)initWithIndexSet:(NSIndexSet *)indexSet
{
   self = [super init];
   
   if (self)
   {
      set = [indexSet retain];
      first = YES;
   }
   
   return self;
}

- (void)dealloc
{
   [set release];
   [super dealloc];
}

- (unsigned int)nextIndex
{
   if (first)
   {
      idx = [set firstIndex];
      first = NO;
   }
   else
      idx = [set indexGreaterThanIndex:idx];

   return idx;
}

@end

@implementation NSIndexSet (TWXNSIndexSet)

- (TWIndexSetEnumerator *)indexEnumerator
{
   return [[[TWIndexSetEnumerator alloc] initWithIndexSet:self] autorelease];
}

@end
