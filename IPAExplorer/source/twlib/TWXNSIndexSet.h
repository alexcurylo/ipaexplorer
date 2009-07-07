//
//  TWXNSIndexSet.h
//
//  Copyright 2009 Trollwerks Inc. All rights reserved.
//

// from http://www.cocoadev.com/index.pl?NSIndexSet

@interface TWIndexSetEnumerator : NSObject
{
   NSIndexSet *set;
   unsigned int idx;
   BOOL first;
}

- (id)initWithIndexSet:(NSIndexSet *)indexSet;
- (unsigned int)nextIndex;

@end

@interface NSIndexSet (TWXNSIndexSet)

- (TWIndexSetEnumerator *)indexEnumerator;

@end
