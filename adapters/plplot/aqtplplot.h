// private functions prototypevoid plD_init_aqt(PLStream *pls);void plD_line_aqt(PLStream *pls, short x1a, short y1a, short x2a, short y2a);void plD_polyline_aqt(PLStream *pls, short *xa, short *ya, PLINT npts);void plD_bop_aqt(PLStream *pls);void plD_eop_aqt(PLStream *pls);void plD_tidy_aqt(PLStream *pls);void plD_state_aqt(PLStream *pls, PLINT op);void plD_esc_aqt(PLStream *pls, PLINT op, void *ptr);