using Common.AssetSystem;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[XLua.LuaCallCSharp]
public static class ExtendDefine
{
    /// <summary>
    /// 扩展 Image 方法，设置Sprite名称 刷新 Sprite
    /// </summary>
    /// <param name="image">扩展的对象</param>
    /// <param name="spriteName">图片资源名称</param>
    /// <param name="isNativeSize"></param>
    public static void ResetSpriteByName(this UnityEngine.UI.Image image, string spriteName, bool isNativeSize = false)
    {
        if (UISpriteManager.Instance != null)
        {
            UISpriteManager.Instance.SetImageSprite(image, spriteName, isNativeSize);
        }
    }

    /// <summary>
    /// 扩展 Image 方法, 设置Sprite名称 刷新 Sprite
    /// </summary>
    /// <param name="image">扩展的对象</param>
    /// <param name="spriteName">图片资源名称</param>
    /// <param name="isNativeSize">是否使用原尺寸</param>
    public static void ResetSpriteByNameAsync(this UnityEngine.UI.Image image, string spriteName, bool isNativeSize = false)
    {
        if (UISpriteManager.Instance != null)
        {
            UISpriteManager.Instance.SetImageSpriteAsync(image, spriteName, isNativeSize);
        }
    }
}
