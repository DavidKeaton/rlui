#include "ui.h"
#include "enums.h"
#include "ui_event.h"

#include <utility>
#include <string>
#include <array>
#include <climits>


/* null event type, for use when no events are available */
const static ui_event null_event = {NUM_EVENTS};

// class: window {{{1
// initializers {{{2
window::window(void)
{
}

window::window(int w, int h, int x, int y)
{
    if(!set_size(w, h)) {
        return;
    }
    if(!set_pos(x, y)) {
        return;
    }
    valid = init();
}

window::~window(void)
{
	shutdown();
}

bool window::init(void)
{
    point max;
    getmaxyx(stdscr, max.y, max.x);
    auto s = get_size();
    auto p = get_pos();
    // check to see if the window would fit properly
    int abs_width = p.first + s.first;
    int abs_height = p.second + s.second;
    if(abs_width > max.x || abs_height > max.y) {
        return false;
    }
    // values for size and height should be valid
	win = newwin(s.second, s.first, p.second, p.first);
	return win != nullptr;
}

void window::shutdown(void)
{
	delwin(win);
}
// }}}2
// properties {{{2
void window::get_size(int &w, int &h) const
{
    w = width;
    h = height;
}

void window::get_pos(int &x, int &y) const
{
    x = this->x;
    y = this->y;
}

const std::pair<int, int> window::get_size(void) const
{
    return std::make_pair(width, height);
}

const std::pair<int, int> window::get_pos(void) const
{
    return std::make_pair(x, y);
}
// }}}2
// modify attributes {{{2
bool window::set_size(int w, int h)
{
    // get the maximum size of the terminal
    point max;
    getmaxyx(stdscr, max.y, max.x);
    // sizes can't be larger than the max term size
    if(w > max.x || w < 0 || h > max.y || h < 0) {
        return false;
    }
    // if width/height is 0, make term full width/height
    this->width = (w == 0) ? max.x : w;
    this->height = (h == 0) ? max.y : h;
    return true;
}

bool window::set_pos(int x, int y)
{
    point max;
    getmaxyx(stdscr, max.y, max.x);
    if(x > max.x || x < 0 || y > max.y || y < 0) {
        return false;
    }
    this->x = x;
    this->y = y;
    return true;
}
// }}}2
// updating window {{{2
void window::update(void)
{
    if(!hidden) {
        wnoutrefresh(win);
    }
    ready = true;
}

// FIXME: this needs to not do `doupdate()'...
void window::refresh(void)
{
    if(!hidden) {
        if(!ready) {
            wrefresh(win);
        } else {
            doupdate();
        }
    }
}
// }}}2
// }}}1
// class: ui_base {{{1
void ui_base::process_events(void)
{
    // gather events, and add them to the queue appropriately
}

const ui_event &ui_base::peek_event(void)
{
    return (!events.empty()) ? events.front() : null_event;
}

void ui_base::sync(void)
{
}

int ui_base::run(const ui_function &func)
{
    int rc = INT_MIN;
    do {
        // gather input/ui events
        process_events();
        while(!events.empty()) {
            // find the userdata for this function, and pass it if there
            auto iter = userdata.find(events.front().type);
            // pass the event along to the user function
            void *data = (iter != userdata.end()) ?
                static_cast<void*>(iter->second) : nullptr;
            rc = func(events.front(), data);
            // delete the event, and continue
            events.pop();
        }
    } while(events.front().type != UI_ON_EXIT);
    return rc;
}

int ui_base::operator()(const ui_function &func)
{
    // TODO: make this do something
    return run(func);
}

void ui_base::refresh(void)
{
}
// }}}1
// class: ui_text {{{1
// initializers {{{2
ui_text::ui_text(void)
{
}

ui_text::~ui_text(void)
{
}

void ui_text::init(void)
{
}
// }}}2
// internal {{{2
void ui_text::prettify(void)
{
    // break the text up between either double spaces or newline
    static const std::array<char[4], 2> tokens = {"\n", "  "}; // TODO: make me OS independent!
    // early exit if no text to beautify
    if(text.empty()) {
        return;
    }
    pretty_text.clear();
    // check over the string one token at a time
    for(const auto &elem : tokens) {
        for(size_t pos = 0; pos < text.length();) {
            // save the position, for a better Earth!
            size_t prior = pos;
            pos = text.find(elem, pos);
            // bail out if no token found
            if(pos == std::string::npos) {
                break;
            }
            // now, simply push back the portion of the text!
            int len = pos - prior;
            // point `pos' to the next character
            pretty_text.push_back(text.substr(pos++, len));
        }
    }
    // TODO: apply colorizing/formatting options here!
    // TODO: (or maybe make it its own function)
}
// }}}2
// getters {{{2
// }}}2
// setters {{{2
void ui_text::set_text(const std::string &text)
{
    this->text = text;
}

void ui_text::clear_text(void)
{
    text.clear();
    pretty_text.clear();
}
// }}}2
// }}}1
// class: ui_button {{{1
void ui_button::on_click(const ui_callback &func)
{
}
// }}}1
