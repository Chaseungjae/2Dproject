shader_type canvas_item;

void fragment() {
    float alpha = UV.x; // 오른쪽 (1.0)  → 왼쪽 (0.0)
    COLOR = texture(TEXTURE, UV);
    COLOR.a *= alpha; // 알파 값에 그라데이션  적용
}
