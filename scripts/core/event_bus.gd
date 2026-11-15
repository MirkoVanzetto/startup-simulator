extends Node
## EventBus - Central decoupled signal bus for Startup Simulator

# Game & State signals
signal game_state_changed(new_state: int, old_state: int)
signal prompt_changed(prompt_text: String)
signal interaction_triggered(target: Node)

# Economy signals
signal funds_changed(current_balance: float, delta: float, reason: String)
signal item_purchased(item_id: String, cost: float)

# Contract signals
signal contract_updated(contract_id: String, status: String)
signal contract_completed(contract_id: String, reward: float, reputation: int)

# Laptop / Computer signals
signal computer_opened()
signal computer_closed()
signal minigame_started(minigame_type: String)
signal minigame_completed(score: float, result_data: Dictionary)

# Dialogue signals
signal dialogue_started(speaker_name: String, text_lines: Array, choices: Array)
signal dialogue_choice_selected(choice_index: int)
signal dialogue_action_triggered(action: String)
signal dialogue_ended()

# Notification signals
signal notification_posted(title: String, message: String, icon_type: String)

# Milestone 3 - Calendar & Simulation signals
signal time_tick(hour: int, minute: int, day: int)
signal day_passed(new_day: int)
signal daily_expenses_billed(total_amount: float, details: Dictionary)
signal random_event_triggered(event_data: Dictionary)
signal random_event_resolved(choice_index: int)
signal contract_marketplace_refreshed()

# Milestone 6 - Employee signals
signal employee_hired(employee_id: String, employee_name: String)
signal employee_fired(employee_id: String)

# Needs, shops & fame signals
signal needs_changed(hunger: float, energy: float)
signal shop_opened(shop_id: String)
signal shop_closed()
signal fame_tier_changed(tier_index: int, tier_name: String)

# Inventory & World Map signals
signal backpack_updated()
signal waypoint_changed(waypoint: Dictionary)

# Side Jobs / Repeatable Activities signals
signal side_job_started(job_id: String, job_data: Dictionary)
signal side_job_progressed(job_id: String, step: int, total: int, detail: String)
signal side_job_completed(job_id: String, reward: float, rep_gain: int)
signal side_job_cancelled(job_id: String)

# Upgrades & OGR Enterprise signals (v1.4)
signal stars_changed(current_stars: int, delta: int, reason: String)
signal upgrade_purchased(upgrade_id: String, new_rank: int)
signal ogr_hub_unlocked()
signal knowledge_upgraded(track_id: String, new_rank: int)
