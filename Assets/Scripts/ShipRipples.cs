using UnityEngine;

public class ShipRipples : MonoBehaviour
{
    public Material waterMat;
    public float rippleStrength = 0.35f;
    public float movementThreshold = 0.2f;
    Vector3 lastPos;
    float cooldown = 0f;

    void Start() { lastPos = transform.position; }

    void Update()
    {
        float speed = (transform.position - lastPos).magnitude / Time.deltaTime;
        if (speed > movementThreshold && cooldown <= 0f)
        {
            // set ripple center & time (shader expects vector)
            Vector3 p = transform.position;
            waterMat.SetVector("_RippleCenter", new Vector4(p.x, p.y, p.z, 0));
            waterMat.SetFloat("_RippleStrength", rippleStrength);
            waterMat.SetFloat("_RippleTime", Time.time);
            cooldown = 0.15f; // throttle ripple updates
        }
        if (cooldown > 0f) cooldown -= Time.deltaTime;

        // optional: decay ripple strength slowly so they fade even if ship stops
        float rs = waterMat.GetFloat("_RippleStrength");
        if (rs > 0.001f)
            waterMat.SetFloat("_RippleStrength", Mathf.Lerp(rs, 0f, Time.deltaTime * 0.6f));

        lastPos = transform.position;
    }
}
