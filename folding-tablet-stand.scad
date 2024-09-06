$fn= $preview ? 32 : 128;        // render more accurately than preview

// =============================
// ===== ADJUSTABLE VALUES =====
// =============================

height = 29;                    // total height of model in mm
thickness = 5;                  // thickness of each paddle in mm

padThickness = 1.75;            // thickness of rubber pads for bottom and for slot

hingeGap = .4;                  // gap between hinges
pinFactor = 2.3;                // factor by which to divide hingeRadius to get radius of hinge pin

openAngle = 60;                 // angle between sides when open
reclineAngle = 20;              // angle of recline of tablet

slotDepth = 20;                 // depth of slot
slotFront = 12;                 // amount of material in front of slot in mm

holeDiameter = 9;               // diameter of holes in base in mm
holeSpacingFactor = 5/6;        // adjusts spacing between holes

tabletHeight = 248;             // height of tablet; used to calculate needed length
tabletWidth = 178;
tabletThickness = 10;           // thickness of tablet (including case)

// =============================
// ===== CALCULATED VALUES =====
// =============================

slotWidth = tabletThickness + padThickness + .5;  // width of slot for tablet to fit in
length = (tabletHeight + height - slotDepth) * sin(reclineAngle + 3) + slotFront + slotWidth;  // length of arm; adding +3 to reclineAngle to provide for slack
hingeRadius = thickness + .5;        // radius of hinge in mm
hingeThickness = (height - hingeGap * 4) / 5;         // thickness of each hinge segment
hingeLocations = [ for (i = [0:4]) (hingeThickness + hingeGap) * i ];
reclineAngle2 = asin((length + hingeRadius) / (.85 * tabletHeight));  // low angle of recline

// =============================
// ========= THE MODEL =========
// =============================

module arm(side) {

    difference() {
        // Main body
        cube([height, length - 2*hingeRadius, thickness]);

        // Cut out slot
        angle = (side == "right") ? openAngle/2 : -openAngle/2;
        x = thickness / cos(angle);
        y = -slotWidth / 2 * tan(angle);
        translate([slotDepth/2 - 5, length - hingeRadius - slotFront - slotWidth, thickness/2])
            rotate([0, angle, 90 + reclineAngle]) {
                cube([slotWidth, slotDepth + 10, x + slotWidth * abs(tan(angle)) + .1], center=true);
                // indentations for rubber pads
                translate([-slotWidth / 2,
                           -slotDepth/2 + 11.5,
                           y])
                    cube([padThickness, 10, x - 1.5], center=true);
                translate([slotWidth / 2,
                           -slotDepth/2 - 1,
                           -y])
                    cube([padThickness, 7.5, x - 1.5], center=true);
            }

        // Cut out holes
        holeLength =  (length - 2*hingeRadius - slotFront - slotWidth - holeDiameter - 2);
        holeSpacing = holeSpacingFactor * holeDiameter;
        for (i = [holeDiameter / 1.5 : holeSpacing : holeLength / 2]) {
            translate([height / 3, i * 2, thickness / 2])
                cylinder(h=thickness + .1, d=holeDiameter, center=true);
            translate([2*height / 3, i * 2 + holeSpacingFactor * holeDiameter, thickness / 2])
                cylinder(h=thickness + .1, d=holeDiameter, center=true);
        }

        // slice off front
        translate([-2, length - 2*hingeRadius - slotFront - slotDepth / 2 * cos(reclineAngle) - .1, -1])
            cube([slotDepth / 2 - 1, slotFront * 2, thickness + 2]);
        // slice off low angle of recline
        translate([5, length - hingeRadius, (side == "right") ? 0 : 5])
        rotate([0, -angle/2, -90 + reclineAngle2])
            cube([slotDepth, slotFront * 4, 3*thickness], center=true);
        // Pads
        translate([0, length - hingeRadius, thickness/2 * cos(reclineAngle2)])
            rotate([0, 0, -90 + reclineAngle2])
            rotate([0, -angle/2, 0])
            // fixme: need to do trig here!
            translate([(side == "right") ? 10.95 + padThickness - .5 : 10.69 + padThickness - .5,
                        3,
                        (side == "right") ? -2.75 : 3.8])
                cube([2*padThickness - .8, 6.5, thickness - 1.25], center=true);

        // indentations for rubber feet
        translate([height, length/2 - hingeRadius - 5, thickness/2])
            cube([2*padThickness - .9, 10, thickness - 1.25], center=true);
        translate([height, length - 2*hingeRadius - 7, thickness/2])
            cube([2*padThickness - .9, 10, thickness - 1.25], center=true);

    } // difference
}


module hinge(top, bottom, side) {
    // top and bottom: 1 need cone added or -1 if need cone subtracted from hinge
    difference() {
        union() {
            cylinder(h=hingeThickness, r=hingeRadius);
            // Add connection to arm
            if (top == -1) {
                translate([hingeRadius - thickness, 0, 0])
                    cube([thickness, hingeRadius + hingeGap + .1, hingeThickness]);
            } else {
                translate([-hingeRadius, 0, 0])
                    cube([thickness, hingeRadius + hingeGap + .1, hingeThickness]);
            }

            // Add stops to prevent opening too wide
            if (top != -1) {
                // translate([hingeRadius - thickness, 0, 0])
                rotate([0, 0, -openAngle])
                    translate([0, hingeRadius * sin(90-openAngle), 0])
                    cube([.6 * hingeRadius, hingeRadius * (1 - sin(90-openAngle)) + hingeGap, hingeThickness]);
            } else {
                // translate([-(hingeRadius - thickness), 0, hingeThickness])
                translate([0, 0, hingeThickness])
                    rotate([0, 180, openAngle])
                    translate([0, hingeRadius * sin(90-openAngle), 0])
                    cube([.6 * hingeRadius, hingeRadius * (1 - sin(90-openAngle)) + hingeGap, hingeThickness]);
            }

        }  // union

        // Remove area for hinge
        if (top == -1) {
            translate([0, 0, -.01])
                cylinder(h=hingeThickness*2 + .1, r=hingeRadius/pinFactor + hingeGap);
        }
        if (bottom == -1) {
            translate([0, 0, hingeThickness/2 + .01])
                cylinder(h=hingeThickness/2, r=hingeRadius/pinFactor + hingeGap);
        }

        // flatten hinge (when open)
        angle = (side == "right") ? -openAngle/2 : openAngle/2;
        // translate([height/2, -hingeRadius, 0])
        translate([0, 0*hingeThickness/2, hingeThickness/2])
            rotate([0, 0, angle])
                translate([0, -1.35 * hingeRadius, 0])
                    cube([hingeRadius * 2, hingeRadius, hingeThickness + 1], center=true);

    }  // difference
}


module paddle(side) {
    union() {

        translate([0, hingeRadius + hingeGap, hingeRadius - thickness])
            arm(side);

        // hinge
        if (side == "right") {
            translate([hingeLocations[0], 0, 0])
                rotate([0, 90, 0])
                hinge(0, 1, side);
            translate([hingeLocations[2], 0, 0])
                rotate([0, 90, 0])
                hinge(1, 1, side);
            translate([hingeLocations[4], 0, 0])
                rotate([0, 90, 0])
                hinge(1, 0, side);
        } else {  // side == "left"
            translate([hingeLocations[1], 0, 2*hingeRadius - thickness])
                rotate([0, 90, 0])
                hinge(-1, -1, side);
            translate([hingeLocations[3], 0, 2*hingeRadius - thickness])
                rotate([0, 90, 0])
                hinge(-1, -1, side);
        }

        // Add hinge pin all the way through
        rotate([0, 90, 0])
            translate([0, 0, 0])
            if (side == "right")
                cylinder(h=height - padThickness, r=hingeRadius/pinFactor);

    }

}

module tablet() {
    // Approximate location of tablet
    rotate([-openAngle/2, 0, 0])
        translate([0,
                   (length - hingeRadius - slotWidth - slotFront) * cos(openAngle/2) - slotFront/3,
                   -tabletWidth / 2])
        rotate([0, 0, reclineAngle])
        translate([-tabletHeight + slotDepth + 1, 0, 0])
        cube([tabletHeight, tabletThickness, tabletWidth]);
}

rotate([0, 90, 0]) translate([-height, 0, 0])  // Rotate and move to correct position on build plate
{
    difference() {
        union() {

            paddle("right");

            // rotate([-openAngle, 0, 0])
            translate([0, 0, -2*hingeRadius + thickness])
                paddle("left");

            // tablet();

        }

        // indentation for rubber foot on hinge
        rotate([0, 90, 0])
            translate([0, 0, height])
            rotate([0, 0, -openAngle/2])
            cube([1.25*hingeRadius, 1.4*hingeRadius, 2*padThickness - .9], center=true);

    }

}
