/* Copyright 2015-2016 Jack Humbert
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#pragma once

#include <dt-bindings/zmk/hid_usage.h>
#include <dt-bindings/zmk/hid_usage_pages.h>
#include <dt-bindings/zmk/modifiers.h>
#include <dt-bindings/zmk/keys.h>

// clang-format off

/*
 * ┌───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───────┐
 * │ ² │ & │ é │ " │ ' │ ( │ - │ è │ _ │ ç │ à │ ) │ = │       │
 * ├───┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─────┤
 * │     │ A │ Z │ E │ R │ T │ Y │ U │ I │ O │ P │ ^ │ $ │     │
 * ├─────┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┐    │
 * │      │ Q │ S │ D │ F │ G │ H │ J │ K │ L │ M │ ù │ * │    │
 * ├────┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴───┴────┤
 * │    │ < │ W │ X │ C │ V │ B │ N │ , │ ; │ : │ ! │          │
 * ├────┼───┴┬──┴─┬─┴───┴───┴───┴───┴───┴──┬┴───┼───┴┬────┬────┤
 * │    │    │    │                        │    │    │    │    │
 * └────┴────┴────┴────────────────────────┴────┴────┴────┴────┘
 */
// Row 1
#define FR_SUP2 GRAVE   // ²  (<)
#define FR_AMPR N1      // &  (ok)
#define FR_EACU N2      // é  (ok)
#define FR_DQUO N3      // "  (ok)
#define FR_QUOT N4      // '  (ok)
#define FR_LPRN N5      // (  (ok)
#define FR_MINS N6      // -  (§)
#define FR_EGRV N7      // è  (ok)
#define FR_UNDS N8      // _  (!)
#define FR_CCED N9      // ç  (ok)
#define FR_AGRV N0      // à  (ok)
#define FR_RPRN MINUS   // )  (ok)
#define FR_EQL  EQUAL   // =  (-) LS(_)
// Row 2
#define FR_A    Q    // A
#define FR_Z    W    // Z
#define FR_E    E    // E
#define FR_R    R    // R
#define FR_T    T    // T
#define FR_Y    Y    // Y
#define FR_U    U    // U
#define FR_I    I    // I
#define FR_O    O    // O
#define FR_P    P    // P
#define FR_CIRC LEFT_BRACKET  // ^  (ok) LS(¨)
#define FR_DLR  RIGHT_BRACE   // $  (*)
// Row 3
#define FR_Q    A    // Q
#define FR_S    S    // S
#define FR_D    D    // D
#define FR_F    F    // F
#define FR_G    G    // G
#define FR_H    H    // H
#define FR_J    J    // J
#define FR_K    K    // K
#define FR_L    L    // L
#define FR_M    SEMI // M  (ok)
#define FR_UGRV SQT  // ù  (ok)
#define FR_ASTR STAR // *  (8)
// Row 4
#define FR_LABK STAR   // <  (8)
#define FR_W    Z      // W
#define FR_X    X      // X
#define FR_C    C      // C
#define FR_V    V      // V
#define FR_B    B      // B
#define FR_N    N      // N
#define FR_COMM M      // ,  (ok) LS(?)
#define FR_SCLN COMMA  // ;  (ok) LS(.)
#define FR_COLN DOT    // :  (ok) LS(/)
#define FR_EXLM SLASH  // !  (=) LS(+)

/* Shifted symbols
 * ┌───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───────┐
 * │   │ 1 │ 2 │ 3 │ 4 │ 5 │ 6 │ 7 │ 8 │ 9 │ 0 │ ° │ + │       │
 * ├───┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─────┤
 * │     │   │   │   │   │   │   │   │   │   │   │ ¨ │ £ │     │
 * ├─────┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┐    │
 * │      │   │   │   │   │   │   │   │   │   │   │ % │ µ │    │
 * ├────┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴───┴────┤
 * │    │ > │   │   │   │   │   │   │ ? │ . │ / │ § │          │
 * ├────┼───┴┬──┴─┬─┴───┴───┴───┴───┴───┴──┬┴───┼───┴┬────┬────┤
 * │    │    │    │                        │    │    │    │    │
 * └────┴────┴────┴────────────────────────┴────┴────┴────┴────┘
 */
// Row 1
#define FR_1    LS(N1) // 1
#define FR_2    LS(N2) // 2
#define FR_3    LS(N3) // 3
#define FR_4    LS(N4) // 4
#define FR_5    LS(N5) // 5
#define FR_6    LS(N6) // 6
#define FR_7    LS(N7) // 7
#define FR_8    LS(N8) // 8
#define FR_9    LS(N9) // 9
#define FR_0    LS(N0) // 0
#define FR_DEG  LS(MINUS)   // °
#define FR_PLUS LS(FR_EQL)  // +
// Row 2
#define FR_DIAE LS(FR_CIRC) // ¨  (dead)
#define FR_PND  LS(FR_DLR)  // £
// Row 3
#define FR_PERC LS(FR_UGRV) // %
#define FR_MICR LS(FR_ASTR) // µ
// Row 4
#define FR_RABK LS(FR_LABK) // >
#define FR_QUES LS(FR_COMM) // ?
#define FR_DOT  LS(FR_SCLN) // .
#define FR_SLSH LS(FR_COLN) // /
#define FR_SECT N5 // §

/* AltGr symbols
 * ┌───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───────┐
 * │   │   │ ~ │ # │ { │ [ │ | │ ` │ \ │   │ @ │ ] │ } │       │
 * ├───┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─────┤
 * │     │   │   │ € │   │   │   │   │   │   │   │   │ ¤ │     │
 * ├─────┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┐    │
 * │      │   │   │   │   │   │   │   │   │   │   │   │   │    │
 * ├────┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴───┴────┤
 * │    │   │   │   │   │   │   │   │   │   │   │   │          │
 * ├────┼───┴┬──┴─┬─┴───┴───┴───┴───┴───┴──┬┴───┼───┴┬────┬────┤
 * │    │    │    │                        │    │    │    │    │
 * └────┴────┴────┴────────────────────────┴────┴────┴────┴────┘
 */
// Row 1
#define FR_TILD RA(FR_EACU) // ~  (dead)
#define FR_HASH RA(FR_DQUO) // #
#define FR_LCBR RA(N5)      // {  (ok)
#define FR_LBRC LS(FR_LCBR) // [  (ok)
#define FR_PIPE RA(FR_MINS) // |
#define FR_GRV  RA(FR_EGRV) // `  (dead)
#define FR_BSLS RA(FR_UNDS) // (backslash)
#define FR_AT   RA(FR_AGRV) // @
#define FR_RCBR RA(MINUS)   // }  (ok)
#define FR_RBRC LS(FR_RCBR) // ]  (ok)
// Row 2
#define FR_EURO LA(FR_DLR) // €  (dead!)
