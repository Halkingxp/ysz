//***************************************************************
// 脚本名称：UISpriteManager
// 类创建人：周  波
// 创建日期：2015.12
// 功能描述：管理界面动态替换的图片资源
//***************************************************************
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Common.AssetSystem
{
    public class UISpriteManager : ManagerBase<UISpriteManager>
    {
        /// <summary>
        /// 设置动态设置图片的 Sprite
        /// </summary>
        /// <param name="image">图片控件</param>
        /// <param name="spriteName">图片名称</param>
        /// <returns></returns>
        public void SetImageSprite(UnityEngine.UI.Image image, string spriteName, bool isNativeSize = false)
        {
            GameObject spriteGo = AssetBundleManager.Instance.LoadAsset<GameObject>(spriteName, unloadAssetBundle: false);
            if (spriteGo != null)
            {
                SpriteRenderer spriteRenderer = spriteGo.GetComponent<SpriteRenderer>();
                if (spriteRenderer != null)
                {
                    if (spriteRenderer.sprite != null)
                    {
                        image.sprite = spriteRenderer.sprite;
                    }
                }
            }
        }

        /// <summary>
        /// 异步设置图片
        /// </summary>
        /// <param name="image"></param>
        /// <param name="spriteName"></param>
        /// <param name="isNativeSize"></param>
        public void SetImageSpriteAsync(UnityEngine.UI.Image image, string spriteName, bool isNativeSize = false)
        {
            StartCoroutine(SetImageSpriteCoroutine(image, spriteName, isNativeSize));
        }

        IEnumerator SetImageSpriteCoroutine(UnityEngine.UI.Image image, string spriteName, bool isNativeSize)
        {
            LoadAssetAsyncOperation operation = AssetBundleManager.Instance.LoadAssetAsync<GameObject>(spriteName, false);
            if (operation != null && !operation.IsDone)
            {
                yield return operation;
            }

            if (operation != null)
            {
                if (image != null)
                {
                    GameObject spriteGo = operation.GetAsset<GameObject>();
                    if (spriteGo != null)
                    {
                        SpriteRenderer spriteRenderer = spriteGo.GetComponent<SpriteRenderer>();
                        if (spriteRenderer != null)
                        {
                            if (spriteRenderer.sprite != null)
                            {
                                image.sprite = spriteRenderer.sprite;
                            }
                        }
                    }
                }
            }
        }

    }
}
