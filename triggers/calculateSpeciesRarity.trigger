trigger calculateSpeciesRarity on Sighting__c (after update, after delete) {
    if (trigger.isUpdate) {
    
        // This if takes care of scenarios where tests have more than 200 records
        //Without this if, the trigger would only execute for the first batch (200 records)
        if (Test.isRunningTest()) {
            SpeciesRarityCalculator.updateSpeciesRarity(trigger.new);
        }
        else {
            if (SpeciesRarityCalculator.firstRun) {
                SpeciesRarityCalculator.firstRun = false;
                SpeciesRarityCalculator.updateSpeciesRarity(trigger.new);
            }
        }
        
    }
    else if (trigger.isDelete) {
        SpeciesRarityCalculator.updateSpeciesRarity(trigger.old);
    }
}