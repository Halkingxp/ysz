using UnityEngine;
using UnityEngine.UI;

/// <summary>
/// 放大镜UI
/// </summary>
public class MagnifyGlassUI : WindowBase
{
    public static string UIAssetName = "MagnifyGlassUI";

    [SerializeField]
    Camera m_TempCamera = null;

    /// <summary>
    /// 放大对象的摄像机
    /// </summary>
    Camera m_TargetCamera = null;

    /// <summary>
    /// 跟随的目标点
    /// </summary>
    RectTransform m_MagnifyTarget = null;

    /// <summary>
    /// 背景资源
    /// </summary>
    [SerializeField]
    RawImage m_BackgroudImage = null;

    /// <summary>
    /// 镜片位置
    /// </summary>
    [SerializeField]
    RectTransform m_GlassRect = null;

    /// <summary>
    /// 放大根节点
    /// </summary>
    [SerializeField]
    RectTransform m_MagnifyGlassRoot = null;

    /// <summary>
    /// 放大部分显示图片
    /// </summary>
    [SerializeField]
    RawImage m_GlassImage = null;

    int GlassHalfWidth = 100;
    int GlassHalfHeight = 100;

    protected override void Start()
    {
        base.Start();
        if (m_GlassRect != null)
        {
            Vector2 sizeDelta = m_GlassRect.rect.size;
            GlassHalfWidth = (int)(sizeDelta.x * 0.5f);
            GlassHalfHeight = (int)(sizeDelta.y * 0.5f);
        }
    }

    protected override void WindowOpened()
    {
        base.WindowOpened();
        m_TargetCamera = null;
        TryGetTargetCamera();

        m_GlassRect.gameObject.SetActive(false);
        m_BackgroudImage.gameObject.SetActive(false);
    }

    public override void RefreshWindowData(object windowData)
    {
        base.RefreshWindowData(windowData);
        if (windowData != null)
        {
            m_MagnifyTarget = windowData as RectTransform; // 跟随的目标点
            m_TargetCamera = null;
            TryGetTargetCamera();
        }
    }

    /// <summary>
    /// 尝试获取放大的摄像机对象
    /// </summary>
    void TryGetTargetCamera()
    {
        if (WindowNode == null)
            return;
        if (WindowNode.ParentWindow.IsRootNode)
        {
            m_TargetCamera = Camera.main;
        }
        else
        {
            if (WindowNode.ParentWindow.WindowMonoBehaviour != null)
            {
                m_TargetCamera = WindowNode.ParentWindow.WindowMonoBehaviour.MyUICamera;
            }
        }

        if (m_TargetCamera != null)
        {
            m_TempCamera.CopyFrom(m_TargetCamera);
            m_TempCamera.enabled = false;
            m_RenderTexture = new RenderTexture(m_TargetCamera.pixelWidth, m_TargetCamera.pixelHeight, 16, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Default);
        }
    }

    protected override void WindowClosed()
    {
        base.WindowClosed();
        if (m_TargetCamera != null)
        {
            m_TargetCamera.targetTexture = null;
            m_TempCamera.enabled = true;
            m_TargetCamera.CopyFrom(m_TempCamera);
            m_TempCamera = null;
        }
        m_BackgroudImage.texture = null;
        m_GlassImage.texture = null;
        m_RenderTexture = null;
        m_TargetCamera = null;
        m_MagnifyTarget = null;
        m_SourceTexture2D = null;
        m_GlassTexture2d = null;

        m_BackgroudImage.gameObject.SetActive(false);
        m_GlassRect.gameObject.SetActive(false);

        Resources.UnloadUnusedAssets();
    }

    RenderTexture m_RenderTexture = null;

    Texture2D m_SourceTexture2D = null;

    /// <summary>
    /// 镜面图片
    /// </summary>
    Texture2D m_GlassTexture2d = null;

    private void Update()
    {
        Resources.UnloadUnusedAssets();

        if (m_TargetCamera == null)
        {
            TryGetTargetCamera();
            if (m_TargetCamera == null)
            {
                return;
            }
        }

        m_TargetCamera.targetTexture = m_RenderTexture;
        m_SourceTexture2D = new Texture2D(m_RenderTexture.width, m_RenderTexture.height, TextureFormat.ARGB32, false);
        RenderTexture.active = m_RenderTexture;

        m_SourceTexture2D.ReadPixels(new Rect(0, 0, m_RenderTexture.width, m_RenderTexture.height), 0, 0);
        m_SourceTexture2D.Apply();

        if (m_BackgroudImage != null)
        {
            m_BackgroudImage.texture = m_RenderTexture;
            m_BackgroudImage.gameObject.SetActive(true);
        }

        Vector3 screenPoint = CalculateTargetScreenPoint();

        if (m_GlassRect != null && m_MagnifyGlassRoot != null)
        {
            Vector2 localPoint;
            RectTransformUtility.ScreenPointToLocalPointInRectangle(m_MagnifyGlassRoot, screenPoint, MyUICamera, out localPoint);
            m_GlassRect.localPosition = localPoint;
        }

        // 设置镜面图片
        m_GlassTexture2d = new Texture2D(GlassHalfWidth * 2, GlassHalfHeight * 2, TextureFormat.ARGB32, false);

        for (int x = 0; x < GlassHalfWidth * 2; x++)
        {
            for (int y = 0; y < GlassHalfHeight * 2; y++)
            {
                m_GlassTexture2d.SetPixel(x, y, m_SourceTexture2D.GetPixel((int)(screenPoint.x + x - GlassHalfWidth), (int)(screenPoint.y + y - GlassHalfHeight)));
            }
        }

        m_GlassTexture2d.Apply();
        if (m_GlassImage != null)
        {
            m_GlassImage.texture = m_GlassTexture2d;
            if (m_GlassRect != null)
            {
                m_GlassRect.gameObject.SetActive(true);
            }
        }
    }

    Vector3 CalculateTargetScreenPoint()
    {
        Vector3 screenPoint;
        if (m_MagnifyTarget != null)
        {
            screenPoint = m_TargetCamera.WorldToScreenPoint(m_MagnifyTarget.position);
        }
        else
        {
            screenPoint = Input.mousePosition;
        }
        return screenPoint;
    }
}
