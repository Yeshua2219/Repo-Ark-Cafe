export default function StatCard({ title, value, icon: Icon }) {
  return (
    <div className="stat-card">
      <div className="stat-card-top">
        <p>{title}</p>

        <div className="stat-icon">
          <Icon size={23} />
        </div>
      </div>

      <h2>{value}</h2>
    </div>
  );
}