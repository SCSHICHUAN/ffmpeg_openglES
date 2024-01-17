#version 300 core
out lowp vec4 FragColor;
in lowp vec2 outTextPos;
uniform sampler2D yTexture;
uniform sampler2D uTexture;
uniform sampler2D vTexture;



void main()
{
    
    highp float y = texture(yTexture, outTextPos).r;
    highp float cb = texture(uTexture, outTextPos).r;
    highp float cr = texture(vTexture, outTextPos).r;
    
    
    /// 按YCbCr转RGB的公式进行数据转换
    highp float r = y + 1.403 * (cr - 0.5);
    highp float g = y - 0.343 * (cb - 0.5) - 0.714 * (cr - 0.5);
    highp float b = y + 1.770 * (cb - 0.5);
    // 通过纹理坐标数据来获取对应坐标色值并传递
    FragColor = vec4(r, g, b, 1.0);
    
}
