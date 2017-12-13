#import "NSExpression+MGLAdditions.h"

#import "MGLTypes.h"
#if TARGET_OS_IPHONE
    #import "UIColor+MGLAdditions.h"
#else
    #import "NSColor+MGLAdditions.h"
#endif
#import "NSPredicate+MGLAdditions.h"

#import <mbgl/style/expression/expression.hpp>

@implementation NSString (MGLExpressionAdditions)

- (id)mgl_expressionArray {
    return self;
}

- (NSString *)mgl_append:(NSString *)other {
    return [self stringByAppendingString:other];
}

@end

@implementation NSNumber (MGLExpressionAdditions)

- (id)mgl_expressionArray {
    return self;
}

@end

@implementation NSArray (MGLExpressionAdditions)

- (id)mgl_expressionArray {
    // TODO: Convert NSArray to “array” expression operator.
    return [self valueForKeyPath:@"mgl_expressionArray"];
}

@end

@implementation NSExpression (MGLAdditions)

- (std::vector<mbgl::Value>)mgl_aggregateMBGLValue {
    if ([self.constantValue isKindOfClass:[NSArray class]] || [self.constantValue isKindOfClass:[NSSet class]]) {
        std::vector<mbgl::Value> convertedValues;
        for (id value in self.constantValue) {
            NSExpression *expression = value;
            if (![expression isKindOfClass:[NSExpression class]]) {
                expression = [NSExpression expressionForConstantValue:expression];
            }
            convertedValues.push_back(expression.mgl_constantMBGLValue);
        }
        return convertedValues;
    }
    [NSException raise:NSInvalidArgumentException
                format:@"Constant value expression must contain an array or set."];
    return {};
}

- (mbgl::Value)mgl_constantMBGLValue {
    id value = self.constantValue;
    if ([value isKindOfClass:NSString.class]) {
        return { std::string([(NSString *)value UTF8String]) };
    } else if ([value isKindOfClass:NSNumber.class]) {
        NSNumber *number = (NSNumber *)value;
        if ((strcmp([number objCType], @encode(char)) == 0) ||
            (strcmp([number objCType], @encode(BOOL)) == 0)) {
            // char: 32-bit boolean
            // BOOL: 64-bit boolean
            return { (bool)number.boolValue };
        } else if (strcmp([number objCType], @encode(double)) == 0) {
            // Double values on all platforms are interpreted precisely.
            return { (double)number.doubleValue };
        } else if (strcmp([number objCType], @encode(float)) == 0) {
            // Float values when taken as double introduce precision problems,
            // so warn the user to avoid them. This would require them to
            // explicitly use -[NSNumber numberWithFloat:] arguments anyway.
            // We still do this conversion in order to provide a valid value.
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                NSLog(@"Float value in expression will be converted to a double; some imprecision may result. "
                      @"Use double values explicitly when specifying constant expression values and "
                      @"when specifying arguments to predicate and expression format strings. "
                      @"This will be logged only once.");
            });
            return { (double)number.doubleValue };
        } else if ([number compare:@(0)] == NSOrderedDescending ||
                   [number compare:@(0)] == NSOrderedSame) {
            // Positive integer or zero; use uint64_t per mbgl::Value definition.
            // We use unsigned long long here to avoid any truncation.
            return { (uint64_t)number.unsignedLongLongValue };
        } else if ([number compare:@(0)] == NSOrderedAscending) {
            // Negative integer; use int64_t per mbgl::Value definition.
            // We use long long here to avoid any truncation.
            return { (int64_t)number.longLongValue };
        }
    } else if ([value isKindOfClass:[MGLColor class]]) {
        auto hexString = [(MGLColor *)value mgl_color].stringify();
        return { hexString };
    } else if (value && value != [NSNull null]) {
        [NSException raise:NSInvalidArgumentException
                    format:@"Can’t convert %s:%@ to mbgl::Value", [value objCType], value];
    }
    return {};
}

- (std::vector<mbgl::FeatureType>)mgl_aggregateFeatureType {
    if ([self.constantValue isKindOfClass:[NSArray class]] || [self.constantValue isKindOfClass:[NSSet class]]) {
        std::vector<mbgl::FeatureType> convertedValues;
        for (id value in self.constantValue) {
            NSExpression *expression = value;
            if (![expression isKindOfClass:[NSExpression class]]) {
                expression = [NSExpression expressionForConstantValue:expression];
            }
            convertedValues.push_back(expression.mgl_featureType);
        }
        return convertedValues;
    }
    [NSException raise:NSInvalidArgumentException
                format:@"Constant value expression must contain an array or set."];
    return {};
}

- (mbgl::FeatureType)mgl_featureType {
    id value = self.constantValue;
    if ([value isKindOfClass:NSString.class]) {
        if ([value isEqualToString:@"Point"]) {
            return mbgl::FeatureType::Point;
        }
        if ([value isEqualToString:@"LineString"]) {
            return mbgl::FeatureType::LineString;
        }
        if ([value isEqualToString:@"Polygon"]) {
            return mbgl::FeatureType::Polygon;
        }
    } else if ([value isKindOfClass:NSNumber.class]) {
        switch ([value integerValue]) {
            case 1:
                return mbgl::FeatureType::Point;
            case 2:
                return mbgl::FeatureType::LineString;
            case 3:
                return mbgl::FeatureType::Polygon;
            default:
                break;
        }
    }
    return mbgl::FeatureType::Unknown;
}

- (std::vector<mbgl::FeatureIdentifier>)mgl_aggregateFeatureIdentifier {
    if ([self.constantValue isKindOfClass:[NSArray class]] || [self.constantValue isKindOfClass:[NSSet class]]) {
        std::vector<mbgl::FeatureIdentifier> convertedValues;
        for (id value in self.constantValue) {
            NSExpression *expression = value;
            if (![expression isKindOfClass:[NSExpression class]]) {
                expression = [NSExpression expressionForConstantValue:expression];
            }
            convertedValues.push_back(expression.mgl_featureIdentifier);
        }
        return convertedValues;
    }
    [NSException raise:NSInvalidArgumentException
                format:@"Constant value expression must contain an array or set."];
    return {};
}

- (mbgl::FeatureIdentifier)mgl_featureIdentifier {
    mbgl::Value mbglValue = self.mgl_constantMBGLValue;

    if (mbglValue.is<std::string>()) {
        return mbglValue.get<std::string>();
    }
    if (mbglValue.is<double>()) {
        return mbglValue.get<double>();
    }
    if (mbglValue.is<uint64_t>()) {
        return mbglValue.get<uint64_t>();
    }
    if (mbglValue.is<int64_t>()) {
        return mbglValue.get<int64_t>();
    }

    return {};
}

static NSDictionary<NSString *, NSString *> *MGLExpressionOperatorsByFunctionNames;

- (id)mgl_expressionArray {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        MGLExpressionOperatorsByFunctionNames = @{
            @"add:to:": @"+",
            @"from:subtract:": @"-",
            @"multiply:by:": @"*",
            @"divide:by:": @"/",
            @"modulus:by:": @"%",
            @"sqrt:": @"sqrt",
            @"log:": @"log10",
            @"ln:": @"ln",
            @"raise:toPower:": @"^",
            @"uppercase:": @"upcase",
            @"lowercase:": @"downcase"
        };
    });
    
    switch (self.expressionType) {
        case NSConstantValueExpressionType:
            // TODO: Convert non-JSON types to JSON types.
            return self.constantValue;
            
        case NSKeyPathExpressionType: {
            return [@[@"get"] arrayByAddingObjectsFromArray:self.keyPath.pathComponents];
        }
            
        case NSFunctionExpressionType: {
            NSString *function = self.function;
            NSString *op = MGLExpressionOperatorsByFunctionNames[function];
            if (op) {
                NSArray *arguments = [self.arguments valueForKeyPath:@"mgl_expressionArray"];
                return [@[op] arrayByAddingObjectsFromArray:arguments];
            } else if ([function isEqualToString:@"average:"]) {
                NSExpression *sum = [NSExpression expressionForFunction:@"sum:" arguments:self.arguments];
                NSExpression *count = [NSExpression expressionForFunction:@"count:" arguments:self.arguments];
                return [NSExpression expressionForFunction:@"divide:by:" arguments:@[sum, count]].mgl_expressionArray;
            } else if ([function isEqualToString:@"sum:"]) {
                NSArray *arguments = [self.arguments.firstObject mgl_expressionArray];
                return [@[@"+"] arrayByAddingObjectsFromArray:arguments];
            } else if ([function isEqualToString:@"count:"]) {
                return @[@"length", self.arguments.firstObject.mgl_expressionArray];
            } else if ([function isEqualToString:@"min:"]) {
                NSArray *arguments = self.arguments.firstObject.mgl_expressionArray;
                return [@[@"min"] arrayByAddingObjectsFromArray:arguments];
            } else if ([function isEqualToString:@"max:"]) {
                NSArray *arguments = self.arguments.firstObject.mgl_expressionArray;
                return [@[@"max"] arrayByAddingObjectsFromArray:arguments];
            } else if ([function isEqualToString:@"exp:"]) {
                // TODO: Implement e in NSExpression.
                NSArray *e = @[@"e"];
                return [NSExpression expressionForFunction:@"raise:toPower:" arguments:@[e, self.arguments.firstObject]].mgl_expressionArray;
            } else if ([function isEqualToString:@"ceiling:"]) {
                return [NSExpression expressionWithFormat:@"trunc:(%@) + TERNARY(modulus:by:(%@, 1) > 0, 1, 0)",
                        self.arguments.firstObject, self.arguments.firstObject].mgl_expressionArray;
            } else if ([function isEqualToString:@"trunc:"]) {
                return [NSExpression expressionWithFormat:@"%@ - modulus:by:(%@, 1)",
                        self.arguments.firstObject, self.arguments.firstObject].mgl_expressionArray;
            } else if ([function isEqualToString:@"abs:"]) {
                return [NSExpression expressionWithFormat:@"%@ * TERNARY(%@ > 0, 1, -1)",
                        self.arguments.firstObject, self.arguments.firstObject].mgl_expressionArray;
            } else if ([function isEqualToString:@"floor:"]) {
                return [NSExpression expressionWithFormat:@"trunc:(%@) - TERNARY(modulus:by:(%@, 1) < 0, 1, 0)",
                        self.arguments.firstObject, self.arguments.firstObject].mgl_expressionArray;
            } else if ([function isEqualToString:@"mgl_append:"]) {
                NSArray *arguments = [self.arguments valueForKeyPath:@"mgl_expressionArray"];
                return [@[@"concat", self.operand.mgl_expressionArray] arrayByAddingObjectsFromArray:arguments];
            } else if ([function isEqualToString:@"noindex:"]) {
                return self.arguments.firstObject.mgl_expressionArray;
            } else if ([function isEqualToString:@"median:"] ||
                       [function isEqualToString:@"mode:"] ||
                       [function isEqualToString:@"stddev:"] ||
                       [function isEqualToString:@"random"] ||
                       [function isEqualToString:@"randomn:"] ||
                       [function isEqualToString:@"now"] ||
                       [function isEqualToString:@"bitwiseAnd:with:"] ||
                       [function isEqualToString:@"bitwiseOr:with:"] ||
                       [function isEqualToString:@"bitwiseXor:with:"] ||
                       [function isEqualToString:@"leftshift:by:"] ||
                       [function isEqualToString:@"rightshift:by:"] ||
                       [function isEqualToString:@"onesComplement:"] ||
                       [function isEqualToString:@"distanceToLocation:fromLocation:"]) {
                [NSException raise:NSInvalidArgumentException
                            format:@"Expression function %@ not yet implemented.", function];
                return nil;
            } else {
                [NSException raise:NSInvalidArgumentException
                            format:@"Unrecognized expression function %@.", function];
                return nil;
            }
        }
            
        case NSConditionalExpressionType: {
            return @[@"case", self.predicate.mgl_expressionArray, self.trueExpression.mgl_expressionArray, self.falseExpression.mgl_expressionArray];
        }
            
        case NSEvaluatedObjectExpressionType:
        case NSVariableExpressionType:
        case NSUnionSetExpressionType:
        case NSIntersectSetExpressionType:
        case NSMinusSetExpressionType:
        case NSSubqueryExpressionType:
        case NSAggregateExpressionType:
        case NSAnyKeyExpressionType:
        case NSBlockExpressionType:
            [NSException raise:NSInvalidArgumentException
                        format:@"Expression type %lu not yet implemented.", self.expressionType];
    }
    
    // An assignment expression type is present in the BNF grammar, but the
    // corresponding NSExpressionType value and property getters are missing.
    if (self.expressionType == 12) {
        [NSException raise:NSInvalidArgumentException
                    format:@"Assignment expressions not yet implemented."];
    }
    
    return nil;
}

@end
