#import <Foundation/Foundation.h>

#include <mbgl/style/filter.hpp>

NS_ASSUME_NONNULL_BEGIN

@interface NSExpression (MGLAdditions)

@property (nonatomic, readonly) mbgl::Value mgl_constantMBGLValue;
@property (nonatomic, readonly) std::vector<mbgl::Value> mgl_aggregateMBGLValue;
@property (nonatomic, readonly) mbgl::FeatureType mgl_featureType;
@property (nonatomic, readonly) std::vector<mbgl::FeatureType> mgl_aggregateFeatureType;
@property (nonatomic, readonly) mbgl::FeatureIdentifier mgl_featureIdentifier;
@property (nonatomic, readonly) std::vector<mbgl::FeatureIdentifier> mgl_aggregateFeatureIdentifier;
@property (nonatomic, readonly) id mgl_expressionArray;

@end

@interface NSString (MGLExpressionAdditions)

@property (nonatomic, readonly) id mgl_expressionArray;

- (NSString *)mgl_append:(NSString *)other;

@end

@interface NSNumber (MGLExpressionAdditions)

@property (nonatomic, readonly) id mgl_expressionArray;

@end

@interface NSArray (MGLExpressionAdditions)

@property (nonatomic, readonly) id mgl_expressionArray;

@end

NS_ASSUME_NONNULL_END
