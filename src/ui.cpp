#include "ui.h"
#include "enums.h"

#include <utility>

// class: window {{{1
// initializers {{{2
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

