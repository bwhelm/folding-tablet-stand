$fn= $preview ? 32 : 128;        // render more accurately than preview

// =============================
// ===== ADJUSTABLE VALUES =====
// =============================

height = 29;                    // total height of model in mm
thickness = 5;                  // thickness of each paddle in mm

padThickness = 1;               // thickness of rubber pads for bottom and for slot

hingeGap = .2;                  // gap between hinges
hingeConeHeight = 2;            // height of cone inside hinge

openAngle = 60;                 // angle between sides when open
reclineAngle = 18;              // angle of recline of tablet

slotDepth = 20;                 // depth of slot
slotFront = 12;                 // amount of material in front of slot in mm

holeDiameter = 9;               // diameter of holes in base in mm
holeSpacingFactor = 5/6;        // adjusts spacing between holes

coneHeight = 2;                 // height of cones in hinge

tabletHeight = 248;             // height of tablet; used to calculate needed length
tabletWidth = 178;
tabletThickness = 10;           // thickness of tablet (including case)

// =============================
// ===== CALCULATED VALUES =====
// =============================

slotWidth = tabletThickness + padThickness * 2 + .5;  // width of slot for tablet to fit in
length = (tabletHeight + height - slotDepth) * sin(reclineAngle + 3) + slotFront + slotWidth;  // length of arm; adding +3 to reclineAngle to provide for slack
hingeRadius = thickness + .5;        // radius of hinge in mm
hingeThickness = height / 5;         // thickness of each hinge segment
hingeLocations = [ for (i = [0:4]) (height / 5 + hingeGap / 4) * i ];

// =============================
// ========= THE MODEL =========
// =============================

module arm(side) {
    // height, length
    difference() {
        // Main body
        cube([height, length - 2*hingeRadius, thickness]);

        // Cut out slot
        angle = (side == "right") ? openAngle/2 : -openAngle/2;
        x = thickness / cos(angle);
        y = -slotWidth / 2 * tan(angle);
        echo(slotWidth * tan(angle));
        translate([slotDepth/2 - 5, length - hingeRadius - slotFront - slotWidth, thickness/2])
            rotate([0, angle, 90 + reclineAngle]) {
                cube([slotWidth, slotDepth + 10, x + slotWidth * abs(tan(angle)) + .1], center=true);
                // indentations for rubber pads
                translate([-slotWidth / 2,
                           -slotDepth/2 + 9,
                           y])
                    cube([padThickness, 15, x - 1], center=true);
                translate([slotWidth / 2,
                           -slotDepth/2 - 1,
                           -y])
                    cube([padThickness, 7.5, x - 1], center=true);
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
        translate([-1, length - 2*hingeRadius - slotFront - slotDepth / 2 * cos(reclineAngle) - .1, -1])
            cube([slotDepth / 2 - 1, slotFront * 2, thickness + 2]);

        // indentations for rubber feet
        translate([height, length/2 - hingeRadius - 7, thickness/2])
            cube([2*padThickness - .5, 10, thickness - 1], center=true);
        translate([height, length - 2*hingeRadius - 10, thickness/2])
            cube([2*padThickness - .5, 10, thickness - 1], center=true);

    } // difference
}


module hinge(top, bottom) {
    // top and bottom: 1 need cone added or -1 if need cone subtracted from hinge
    difference() {
        union() {
            cylinder(h=hingeThickness - hingeGap, r=hingeRadius);
            // Add connection to arm
            if (top == -1) {
                translate([hingeRadius - thickness, 0, 0])
                    cube([thickness, hingeRadius + hingeGap + .1, hingeThickness - hingeGap]);
            } else {
                translate([-hingeRadius, 0, 0])
                    cube([thickness, hingeRadius + hingeGap + .1, hingeThickness - hingeGap]);
            }

            // Add cones
            if (top == 1) {
                translate([0, 0, -coneHeight])
                    cylinder(h=coneHeight, d1=0, r2=hingeRadius);
            }
            if (bottom == 1) {
                translate([0, 0, hingeThickness - hingeGap])
                    cylinder(h=coneHeight, d2=0, r1=hingeRadius);
            }

            // Add stops to prevent opening too wide
            if (top != -1) {
                // translate([hingeRadius - thickness, 0, 0])
                rotate([0, 0, -openAngle])
                    translate([0, hingeRadius * sin(90-openAngle), 0])
                    cube([hingeRadius/2, hingeRadius * (1 - sin(90-openAngle)) + hingeGap, hingeThickness - hingeGap]);
            } else {
                // translate([-(hingeRadius - thickness), 0, hingeThickness - hingeGap])
                translate([0, 0, hingeThickness - hingeGap])
                    rotate([0, 180, openAngle])
                    translate([0, hingeRadius * sin(90-openAngle), 0])
                    cube([hingeRadius/2, hingeRadius * (1 - sin(90-openAngle)) + hingeGap, hingeThickness - hingeGap]);
            }

        }  // union

        // Remove cones
        if (top == -1) {
            translate([0, 0, -.01])
                cylinder(h=coneHeight, d2=0, r1=hingeRadius);
        }
        if (bottom == -1) {
            translate([0, 0, hingeThickness - hingeGap - coneHeight + .01])
                cylinder(h=coneHeight, d1=0, r2=hingeRadius);
        }

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
                hinge(0, 1);
            translate([hingeLocations[2], 0, 0])
                rotate([0, 90, 0])
                hinge(1, 1);
            translate([hingeLocations[4], 0, 0])
                rotate([0, 90, 0])
                hinge(1, 0);
        } else {  // side == "left"
            translate([hingeLocations[1], 0, 2*hingeRadius - thickness])
                rotate([0, 90, 0])
                hinge(-1, -1);
            translate([hingeLocations[3], 0, 2*hingeRadius - thickness])
                rotate([0, 90, 0])
                hinge(-1, -1);
        }

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
        paddle("right");

        // indentation for rubber foot
        rotate([0, 90, 0])
            translate([0, 0, height])
            rotate([0, 0, openAngle/4])
                cube([1.25*hingeRadius, 1.25*hingeRadius, 1], center=true);

    }

    // rotate([-openAngle, 0, 0])
    translate([0, 0, -2*hingeRadius + thickness])
        paddle("left");

    // tablet();

}
