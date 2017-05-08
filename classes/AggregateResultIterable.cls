global class AggregateResultIterable implements Iterable<AggregateResult> {
    private String query;
    private String validationStatus = 'Approved';
    
    global AggregateResultIterable(String query, String validationStatus) {
        this.query = query;
        this.validationStatus = validationStatus;
    }
    
    global Iterator<AggregateResult> Iterator() {
        return new AggregateResultIterator(query, validationStatus);
    }
}