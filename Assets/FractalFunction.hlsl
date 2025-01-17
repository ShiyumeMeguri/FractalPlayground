#ifndef FRACTAL_FUNCTION_INCLUDED
#define FRACTAL_FUNCTION_INCLUDED

// (1) 定义基于原 A 中的复数运算工具函数
float2 cx_mul(float2 a, float2 b)
{
    return float2(
        a.x*b.x - a.y*b.y,
        a.x*b.y + a.y*b.x
    );
}

float2 cx_sqr(float2 a)
{
    float x2 = a.x*a.x;
    float y2 = a.y*a.y;
    float xy = a.x*a.y;
    return float2(x2 - y2, xy + xy);
}

float2 cx_cube(float2 a)
{
    float x2 = a.x*a.x;
    float y2 = a.y*a.y;
    float d  = x2 - y2;
    // 按照 A 中 feather 分形的实现方式
    return float2(
        a.x*(d - y2 - y2),
        a.y*(x2 + x2 + d)
    );
}

float2 cx_div(float2 a, float2 b)
{
    float denom = 1.0 / (b.x*b.x + b.y*b.y);
    float2 numerator = float2(
        a.x*b.x + a.y*b.y,
        a.y*b.x - a.x*b.y
    );
    return numerator * denom;
}

float2 cx_sin(float2 a)
{
    // A 中同名函数
    return float2(
        sin(a.x)*cosh(a.y),
        cos(a.x)*sinh(a.y)
    );
}

float2 cx_cos(float2 a)
{
    // A 中同名函数
    return float2(
        cos(a.x)*cosh(a.y),
        -sin(a.x)*sinh(a.y)
    );
}

float2 cx_exp(float2 a)
{
    // A 中同名函数
    float r = exp(a.x);
    return float2(
        r*cos(a.y),
        r*sin(a.y)
    );
}


// (2) 定义所有分形函数 (与 A 中同名、同逻辑)
float2 mandelbrot(float2 z, float2 c)
{
    return cx_sqr(z) + c;
}

float2 burning_ship(float2 z, float2 c)
{
    float x = z.x;
    float y = z.y;
    return float2(x*x - y*y, 2.0*abs(x*y)) + c;
}

float2 feather(float2 z, float2 c)
{
    // z -> (z^3 / (1 + z*z)) + c
    float2 one = float2(1.0, 0.0);
    float2 zSquared = z * z;
    return cx_div(cx_cube(z), (one + zSquared)) + c;
}

float2 sfx(float2 z, float2 c)
{
    // z -> z*|z|^2 - (z*(c^2))
    // 实际为: z * dot(z,z) - cx_mul(z, c*c)
    float d = dot(z,z);
    float2 cc2 = float2(c.x*c.x - c.y*c.y, 2*c.x*c.y);
    return z*d - cx_mul(z, cc2);
}

float2 henon(float2 z, float2 c)
{
    // z -> (1 - c.x*z.x^2 + z.y, c.y*z.x)
    return float2(
        1.0 - c.x*z.x*z.x + z.y,
        c.y * z.x
    );
}

float2 duffing(float2 z, float2 c)
{
    // z -> (z.y, -c.y*z.x + c.x*z.y - z.y^3)
    return float2(
        z.y,
        -c.y*z.x + c.x*z.y - z.y*z.y*z.y
    );
}

float2 ikeda(float2 z, float2 c)
{
    // z -> (1 + c.x*(z.x*cos(t) - z.y*sin(t)), c.y*(z.x*sin(t) + z.y*cos(t)))
    // 其中 t = 0.4 - 6/(1 + |z|^2)
    float t = 0.4 - 6.0 / (1.0 + dot(z,z));
    float st = sin(t);
    float ct = cos(t);
    return float2(
        1.0 + c.x*(z.x*ct - z.y*st),
        c.y*(z.x*st + z.y*ct)
    );
}

float2 chirikov(float2 z, float2 c)
{
    // z -> (x + c.x*y, y + c.y*sin(x + c.x*y))
    // 但原 A 中写法：
    // z.y += c.y * sin(z.x);
    // z.x += c.x * z.y;
    // return z;
    //
    // 这里直接照搬 A 中逻辑:
    z.y += c.y * sin(z.x);
    z.x += c.x * z.y;
    return z;
}


// (3) 给出一个统一接口：根据 fractalType 选择不同分形
float2 applySelectedFractal(int fractalType, float2 z, float2 c)
{
    switch (fractalType)
    {
        case 0:  return mandelbrot(z, c);
        case 1:  return burning_ship(z, c);
        case 2:  return feather(z, c);
        case 3:  return sfx(z, c);
        case 4:  return henon(z, c);
        case 5:  return duffing(z, c);
        case 6:  return ikeda(z, c);
        case 7:  return chirikov(z, c);
        default: return mandelbrot(z, c); 
    }
}

#endif // FRACTAL_FUNCTION_INCLUDED
