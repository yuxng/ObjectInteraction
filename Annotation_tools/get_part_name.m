function pnames = get_part_name(cls)

switch cls
    case 'chair'
        pnames = {'back', 'seat', 'leg1', 'leg2', 'leg3', 'leg4'};
    case 'car'
        pnames = {'head', 'left', 'right', 'front', 'back', 'tail'};
    case 'bed'
        pnames = {'front', 'left', 'right', 'up', 'back'};        
    case 'sofa'
        pnames = {'front', 'seat', 'back', 'left', 'right'};
    case 'table'
        pnames = {'top', 'leg1', 'leg2', 'leg3', 'leg4'};
    otherwise
        pnames = [];
        return;
end