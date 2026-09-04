## Home Profile

Target source of truth: Home Assistant.

- Migrate residential automations progressively to Home Assistant in future authorized work.
- Keep Smart Life/Tuya as a device or cloud bridge where necessary.
- Keep Alexa+ as a useful voice and automation interface.
- Agents integrate primarily through Home Assistant tools, MCP, or API rather than depending on Alexa as the integration layer.
- Prefer high-level tools such as `good_night()`, `leave_home()`, `get_house_energy()`, and `turn_off_office()` instead of exposing hundreds of raw entities to a model.

### Safety tiers

- `AUTO / LOW RISK`: query temperature, consumption, or state; control explicitly permitted lighting; run explicitly safe scenes.
- `CONFIRMATION`: materially change climate control, turn off important equipment, or alter automations.
- `STRONG CONFIRMATION`: unlock doors, open a garage, change security or access controls, or operate critical devices.

This profile is a boundary and safety contract only. It does not migrate Smart Life, install Home Assistant, or change any residence.
