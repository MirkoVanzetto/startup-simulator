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
